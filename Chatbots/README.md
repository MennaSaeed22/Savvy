# 🤖 Chatbot with LangChain, Fireworks & RAG

A smart chatbot powered by **LangChain**, **Fireworks LLM & Embeddings**, designed to provide accurate, personalized answers.  
It operates in **two modes**:  
- **Insights Mode** for smart saving tips  
- **Transactions Mode** to categorize financial data  

---

## 📌 Features

- 🔗 Integrated LangChain, Fireworks, Supabase, and FastAPI  
- 💬 One chatbot with **two modes**:
  - **Insights Mode** – provides smart saving tips and suggestions  
  - **Transactions Mode** – extracts and organizes user financial data  
- 📄 Unified retrieval from PDFs, Supabase storage, and structured files (CSV/Excel)  
- 🔐 User-specific filtering using metadata (e.g., `user_id`)  
- 🧠 Schema-enforced prompts for accurate information extraction  
- 🛠️ Custom parser to structure LLM output  
- ⚡ Real-time responses via FastAPI backend  

---

## 🚀 How It Works

1. **User Query** → Sent via chat in either mode  
2. **Retrieval** → Relevant context fetched from Supabase or files  
3. **Augmentation** → Query + context passed to Fireworks LLM  
4. **Response** → Personalized answer returned  
