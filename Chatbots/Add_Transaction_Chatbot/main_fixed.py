import os
from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from typing import Optional
from langchain_fireworks import Fireworks
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv
import re
from dateparser import parse as date_parse
from dotenv import load_dotenv
load_dotenv()  # Loads .env into environment variables

import os
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
API_KEY = os.getenv("API_KEY")
DEFAULT_USER_ID = os.getenv("DEFAULT_USER_ID")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
llm = Fireworks(api_key=FW_API_KEY, model="accounts/fireworks/models/deepseek-v3", temperature=1.0, max_tokens=1024)


#---- BUSINESS LOGIC ----#

def process_transaction_with_llm(text):
    transaction_prompt = """
    Extract transaction details from the following text and classify the amount as either income or expense.
    If it's an expense, put amount in EXPENSE; if it’s income, put amount in INCOME. Extract date (handle relative dates like 'yesterday'), a description, and the category.
    If a specific date is not mentioned, assume today's date. If you cant classify the amount as either income or expense,
    assume it is expense and keep it uncategorized. Provide a natural response about the spending.

    Text: {input_text}

    Current date: {current_date}

    Format your response as follows:
    DATE: [Extract the date, handle relative dates like 'this morning', 'yesterday', 'last week', etc.]
    EXPENSE: [amount, if spending; leave blank if not]
    INCOME: [amount, if income; leave blank if not]
    CATEGORY: [Classify into one of if expense: Food, Health, Transportation, Entertainment, Fashion, Lifestyle, Education
               Classify into one of if income: Salary, Part-time, Investments, Bonus, Refunds]
    Description: [one or two word description of the transaction]
    FEEDBACK: [Provide a natural, conversational response about the spending. Consider:
    - If it's a good deal or expensive for that category
    - Suggest money-saving tips if relevant
    - Compliment good financial decisions
    - Express concern for unusually high spending
    - Comment on the timing or necessity of the purchase
    Make it sound natural and varied.]

    Example:
    Input: "I got today 2,000 EGP from upwork"
    DATE: 2024-01-30
    INCOME: 2000
    CATEGORY: Part-time
    DESCRIPTION: upwork
    FEEDBACK: That’s wonderful—congrats on your part-time job!
    
    Input: "Bought lunch for 50 EGP yesterday"
    DATE: 2024-01-29
    EXPENSE: 50
    CATEGORY: Food
    DESCRIPTION: lunch
    FEEDBACK: That's a reasonable amount for lunch! If you're looking to save more, you might consider bringing lunch from home occasionally.
    """
    current_date = datetime.now().strftime('%Y-%m-%d')
    formatted_prompt = transaction_prompt.format(
        input_text=text,
        current_date=current_date
    )
    response = llm.invoke(formatted_prompt)
    return response

def parse_llm_response(response):
    # Simple regex parses as before
    date_match = re.search(r"DATE:\s*(.*)", response)
    date_str = date_match.group(1).strip() if date_match else None
    if not date_str or date_str.lower() == "unknown":
        date_obj = datetime.now()
    else:
        date_obj = date_parse(date_str)
        if not date_obj:
            date_obj = datetime.now()
    date_iso = date_obj.strftime("%Y-%m-%d")

    expense_match = re.search(r"EXPENSE:\s*([\d.]+)", response, re.IGNORECASE)
    income_match = re.search(r"INCOME:\s*([\d.]+)", response, re.IGNORECASE)
    expense = float(expense_match.group(1)) if expense_match else 0.0
    income = float(income_match.group(1)) if income_match else 0.0

    desc_match = re.search(r"DESCRIPTION:\s*(.*)", response, re.IGNORECASE)
    description = desc_match.group(1).strip() if desc_match and desc_match.group(1).strip() else None

    category_match = re.search(r"CATEGORY:\s*(.*)", response)
    category = category_match.group(1).strip() if category_match and category_match.group(1).strip() else None

    feedback_match = re.search(r"FEEDBACK:\s*(.*)", response)
    feedback = feedback_match.group(1).strip() if feedback_match else ""

    return {
        "date": date_iso,
        "expense": expense,
        "income": income,
        "category": category,
        "description": description,
        "feedback": feedback
    }

def get_category_id(category_name: str, supabase):
    if not category_name:
        return None
    cat_response = supabase.table("categories").select("category_id").eq("category_name", category_name).execute()
    cat_data = cat_response.data
    if cat_data:
        return cat_data[0]["category_id"]
    else:
        return None

def add_transaction_from_llm(llm_response, user_id, supabase):
    extracted = parse_llm_response(llm_response)
    description_valid = extracted["description"] not in (None, "", "No Description")
    amount_valid = (extracted["expense"] > 0 or extracted["income"] > 0)
    if not description_valid or not amount_valid:
        return "❌ Cannot add transaction: missing information."

    category_id = get_category_id(extracted["category"], supabase)
    new_transaction = {
        "income": extracted["income"],
        "expenses": extracted["expense"],
        "description": extracted["description"],
        "created_at": extracted["date"],
        "user_id": user_id,
        "category_id": category_id
    }
    response = supabase.table("transactions").insert(new_transaction).execute()

    tx_type = "income" if extracted["income"] > 0 else "expense"
    tx_value = extracted["income"] if extracted["income"] > 0 else extracted["expense"]

    user_reply = (
        f"✅ Added {tx_type} transaction: {extracted['description']}, "
        f"{tx_value} EGP, "
        f"date: {extracted['date']}"
    )
    if extracted["category"]:
        user_reply += f", category: {extracted['category']}."
    else:
        user_reply += "."
    if extracted["feedback"]:
        user_reply += f"\n💬 {extracted['feedback']}"
    return user_reply

#---- FASTAPI PART ----#
app = FastAPI(title="Smart Finance LLM Assistant")

class TransactionIn(BaseModel):
    text: str
    user_id: Optional[str] = USER_ID

@app.post("/parse_transaction")
async def parse_transaction(input: TransactionIn):
    llm_response = process_transaction_with_llm(input.text)
    parsed = parse_llm_response(llm_response)
    return parsed

@app.post("/add_transaction")
async def add_transaction_api(input: TransactionIn):
    llm_response = process_transaction_with_llm(input.text)
    result = add_transaction_from_llm(llm_response, input.user_id, supabase)
    return {"result": result}

@app.get("/")
def read_root():
    return {"msg": "Finance Assistant is running."}