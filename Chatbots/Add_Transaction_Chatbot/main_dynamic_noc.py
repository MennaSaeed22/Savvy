import os
from langchain_fireworks import Fireworks
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv
import re
from dateparser import parse as date_parse

# --- 1. LOAD CONFIG FROM .env ---
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
API_KEY = os.getenv("API_KEY")
DEFAULT_USER_ID = os.getenv("DEFAULT_USER_ID")


supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
llm = Fireworks(api_key=API_KEY, model="accounts/fireworks/models/deepseek-v3", temperature=1.0, max_tokens=1024)


# --- 2. PER-USER CATEGORY FETCHING ---
def fetch_user_categories(user_id, supabase, type_group="expense"):
    cat_type = 'Expense' if type_group.lower() == "expense" else 'Income'
    response = (
        supabase
        .table("categories")
        .select("*")
        .eq("user_id", user_id)
        .eq("category_type", cat_type)
        .execute()
    )
    cat_data = response.data
    categories = [c["category_name"] for c in cat_data]
    return categories

# --- 3. TRANSACTION EXTRACTION & PROMPTING ---
def process_transaction_with_llm(text, user_id, supabase):
    expense_categories = fetch_user_categories(user_id, supabase, "expense")
    income_categories = fetch_user_categories(user_id, supabase, "income")
    expense_list = ", ".join(expense_categories) if expense_categories else "Uncategorized"
    income_list = ", ".join(income_categories) if income_categories else "Uncategorized"
    
    # << STRONGLY ENFORCE CATEGORY RESTRICTION IN PROMPT >>
    transaction_prompt = f"""
Extract transaction details from the following text and classify the amount as either income or expense.
If it's an expense, put amount in EXPENSE; if it’s income, put amount in INCOME. Extract date (handle relative dates like 'yesterday'), a description, and the category.
If a specific date is not mentioned, assume today's date. If you can't classify the amount, assume it is expense and keep it uncategorized.
IMPORTANT: For CATEGORY, choose exactly one from this EXPENSE LIST: {expense_list}
and exactly one from this INCOME LIST: {income_list}
If none fit, use "Uncategorized" as the category. DO NOT invent new categories.

Text: {{input_text}}

Current date: {{current_date}}

Format your response as follows:
DATE: ...
EXPENSE: ...
INCOME: ...
CATEGORY: ...
DESCRIPTION: ...
FEEDBACK: ...

Example:
Input: "Bought lunch for 50 EGP yesterday"
DATE: 2024-01-29
EXPENSE: 50
CATEGORY: Groceries    # (should be one of user's categories)
DESCRIPTION: lunch
FEEDBACK: That's a reasonable amount for lunch!
    """.replace("{input_text}", text).replace("{current_date}", datetime.now().strftime('%Y-%m-%d'))

    response = llm.invoke(transaction_prompt)
    return response

# --- 4. PARSE LLM RESPONSE ---
def parse_llm_response(response):
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

# --- 5. CATEGORY ID LOOKUP ---
def get_category_id(category_name: str, user_id, supabase):
    if not category_name:
        return None
    cat_response = (
        supabase
        .table("categories")
        .select("category_id")
        .eq("category_name", category_name)
        .eq("user_id", user_id)
        .execute()
    )
    cat_data = cat_response.data
    if cat_data:
        return cat_data[0]["category_id"]
    else:
        return None

# --- 6. TRANSACTION DB INSERT ---
def add_transaction_from_llm(llm_response, user_id, supabase):
    extracted = parse_llm_response(llm_response)
    description_valid = extracted["description"] not in (None, "", "No Description")
    amount_valid = (extracted["expense"] > 0 or extracted["income"] > 0)

    if not description_valid or not amount_valid:
        return "❌ Cannot add transaction: missing information."

    # Validate category strictly
    # If not in user's categories, default to "Uncategorized"
    user_expense_cats = set(fetch_user_categories(user_id, supabase, "expense"))
    user_income_cats = set(fetch_user_categories(user_id, supabase, "income"))
    if extracted["category"]:
        if extracted["category"] not in user_expense_cats and extracted["category"] not in user_income_cats:
            extracted["category"] = "Uncategorized"

    category_id = get_category_id(extracted["category"], user_id, supabase)
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

# --- 7. DEMO TESTS ---

if __name__ == "__main__":
    TEST_USER_ID = DEFAULT_USER_ID

    test_inputs = [
        "Had dinner for 150 EGP last night",
        "work on tasks got 500",
        "got 500",
        "SON 200",
        "catii eat 200",
        "Received salary 8000 EGP today"
    ]
    for txt in test_inputs:
        print("\n-----------------------------")
        print("Input:", txt)
        llm_response = process_transaction_with_llm(txt, TEST_USER_ID, supabase)
        print("LLM Raw Output:", llm_response)
        result = add_transaction_from_llm(llm_response, TEST_USER_ID, supabase)
        print("Result:", result)