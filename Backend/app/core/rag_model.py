import os
import logging
from dotenv import load_dotenv
from datetime import datetime
from langchain_fireworks import Fireworks, FireworksEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory
from langchain.prompts import PromptTemplate
from langchain.retrievers import EnsembleRetriever
from langchain.schema import Document
from supabase import create_client
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores import FAISS
from typing import Dict, Any

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load .env variables
load_dotenv()
api_key = os.getenv("API_KEY")
supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_KEY")

if not all([api_key, supabase_url, supabase_key]):
    logger.error("Missing one or more required environment variables.")

# Initialize LLM and embeddings
llm = Fireworks(api_key=api_key, model="accounts/fireworks/models/deepseek-v3", temperature=1.0, max_tokens=512, top_p=0.9, frequency_penalty=0.5)
embeddings = FireworksEmbeddings(api_key=api_key)

# PDF files
pdf_files = [
    os.path.join("app", "Pdfs", fname) for fname in [
        "1_55_ways_to_save.pdf", "40MoneyManagementTips.pdf", "beginners-guide-to-saving-2024.pdf",
        "How-to-Manage-your-Finances.pdf", "pdf_50_20_30.pdf", "Personal-Finance-Management-Handbook.pdf",
        "reach-my-financial-goals.pdf", "tips-to-manage-your-money.pdf"
    ]
]

class FinancialChatbot:
    def __init__(self):
        self.pdf_vector_store = None
        self.user_sessions = {}
        self._initialize_pdf_knowledge_base()

    def _initialize_pdf_knowledge_base(self):
        try:
            documents = []
            for pdf in pdf_files:
                if os.path.exists(pdf):
                    loader = PyPDFLoader(pdf)
                    documents.extend(loader.load())
            if not documents:
                logger.warning("No PDF documents loaded.")
                return

            splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
            chunks = splitter.split_documents(documents)
            texts = [chunk.page_content for chunk in chunks]
            pdf_embeddings = embeddings.embed_documents(texts)

            self.pdf_vector_store = FAISS.from_texts(texts=texts, embedding=embeddings)
            logger.info("PDF vector store initialized.")
        except Exception as e:
            logger.error(f"PDF init failed: {e}")

    def _fetch_user_transactions(self, user_id: str):
        supabase = create_client(supabase_url, supabase_key)
        try:
            response = supabase.table("transactions").select("*").eq("user_id", user_id).execute()
            return response.data
        except Exception as e:
            logger.error(f"Failed fetching transactions for user {user_id}: {e}")
            return []

    def _create_user_transaction_vector_store(self, user_id: str):
        data = self._fetch_user_transactions(user_id)
        if not data:
            return None, None

        raw_docs = []
        latest_date = None

        for tx in data:
            created = tx.get("created_at")
            if created:
                created_dt = datetime.fromisoformat(created)
                latest_date = max(latest_date, created_dt) if latest_date else created_dt

            raw_docs.append(
                Document(
                    page_content=(
                        f"Transaction ID: {tx.get('transaction_id', 'Unknown')}\n"
                        f"Date: {tx.get('created_at', 'Unknown date')}\n"
                        f"Type: {tx.get('transaction_type', 'Unknown')}\n"
                        f"Amount: {tx.get('amount', 0)} EGP\n"
                        f"Category ID: {tx.get('category_id', 'Unknown')}\n"
                        f"Description: {tx.get('description', 'No description')}"
                    ),
                    metadata={"source": "transactions", "user_id": user_id}
                )
            )

        splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
        chunks = [chunk for doc in raw_docs for chunk in splitter.split_documents([doc])]

        texts = [chunk.page_content for chunk in chunks]
        tx_embeddings = embeddings.embed_documents(texts)

        tx_vector_store = FAISS.from_texts(texts=texts, embedding=embeddings)
        return tx_vector_store, latest_date

    def _get_or_create_user_session(self, user_id: str):
        session = self.user_sessions.get(user_id)
        need_refresh = False

        # Check if there's newer transaction data
        new_data = self._fetch_user_transactions(user_id)
        latest = None
        if new_data:
            for tx in new_data:
                if tx.get("created_at"):
                    dt = datetime.fromisoformat(tx["created_at"])
                    latest = max(latest, dt) if latest else dt

        if session:
            last_checked = session.get("last_transaction_check")
            if latest and last_checked and latest > last_checked:
                logger.info(f"Detected new transactions for {user_id}, refreshing...")
                self.refresh_user_data(user_id)
                need_refresh = True

        if user_id not in self.user_sessions or need_refresh:
            tx_vector_store, latest_tx_time = self._create_user_transaction_vector_store(user_id)

            retrievers = []
            weights = []

            if self.pdf_vector_store:
                retrievers.append(self.pdf_vector_store.as_retriever(search_kwargs={"k": 5}))
                weights.append(0.5)

            if tx_vector_store:
                retrievers.append(tx_vector_store.as_retriever(search_kwargs={"k": 3}))
                weights.append(0.5)

            combined_retriever = (
                EnsembleRetriever(retrievers=retrievers, weights=weights)
                if len(retrievers) > 1 else retrievers[0]
            )

            prompt = PromptTemplate.from_template("""
You are a helpful financial assistant. Use the following context to help the user:
Context includes:
- General advice from PDFs
- Their transaction history (if available)

Context:
{context}

Chat History:
{chat_history}

Current Question:
{question}

Respond with short, personalized, actionable advice.
""")

            memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)

            chain = ConversationalRetrievalChain.from_llm(
                llm=llm,
                retriever=combined_retriever,
                memory=memory,
                chain_type="stuff",
                combine_docs_chain_kwargs={"prompt": prompt},
                output_key="answer",
            )

            self.user_sessions[user_id] = {
                "chain": chain,
                "memory": memory,
                "last_transaction_check": latest_tx_time or datetime.now(),
            }

        return self.user_sessions[user_id]

    def get_chat_response(self, question: str, user_id: str) -> Dict[str, Any]:
        if not user_id:
            return {"error": "User ID is required", "answer": None}

        try:
            session = self._get_or_create_user_session(user_id)
            result = session["chain"].invoke({"question": question})
            return {"answer": result["answer"]}
        except Exception as e:
            logger.error(f"Chat error for user {user_id}: {e}")
            return {"error": str(e), "answer": None}

    def refresh_user_data(self, user_id: str):
        if user_id in self.user_sessions:
            del self.user_sessions[user_id]
            logger.info(f"User session refreshed: {user_id}")


# Initialize
financial_chatbot = FinancialChatbot()

# API wrapper
def get_chat_response(question: str, user_id: str) -> Dict[str, Any]:
    logger.info(f"Incoming chat: {user_id} -> {question}")
    return financial_chatbot.get_chat_response(question, user_id)