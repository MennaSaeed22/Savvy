import os
from langchain_fireworks import Fireworks
from datetime import datetime
import re
from dateparser import parse as date_parse
from supabase import create_client, Client
from dotenv import load_dotenv

# ---- 1. ENVIRONMENT & CLIENT INIT ---- #
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
API_KEY = os.getenv("API_KEY")
DEFAULT_USER_ID = os.getenv("DEFAULT_USER_ID")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
llm = Fireworks(
    api_key=API_KEY,
    model="accounts/fireworks/models/deepseek-v3",
    temperature=1.0,
    max_tokens=1024
)

# ---- 2. USER CATEGORY CACHE ---- #
user_categories_cache = {}

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

def update_user_categories_cache(user_id, supabase):
    expense_categories = fetch_user_categories(user_id, supabase, type_group="expense")
    income_categories = fetch_user_categories(user_id, supabase, type_group="income")
    user_categories_cache[user_id] = {
        "expense": expense_categories,
        "income": income_categories
    }

def get_cached_user_categories(user_id, supabase):
    if user_id not in user_categories_cache:
        update_user_categories_cache(user_id, supabase)
    return user_categories_cache[user_id]

# ---- 3. TRANSACTION EXTRACTION WITH LLM ---- #
def process_transaction_with_llm(text, user_id, supabase):
    categories = get_cached_user_categories(user_id, supabase)
    expense_categories = categories['expense']
    income_categories = categories['income']
    expense_list = ", ".join(expense_categories) or "Uncategorized"
    income_list = ", ".join(income_categories) or "Uncategorized"
    
    transaction_prompt = f"""
Extract transaction details from the following text and classify the amount as either income or expense.
If it's an expense, put amount in EXPENSE; if it’s income, put amount in INCOME. Extract date (handle relative dates like 'yesterday'), a description, and the category. 
If a specific date is not mentioned, assume today's date. If you can't classify the amount, assume it is expense and keep it uncategorized.
IMPORTANT: For CATEGORY, choose exactly one from this EXPENSE LIST: {expense_list}
and exactly one from this INCOME LIST: {income_list}
Do NOT invent new categories. If none fit, use "Uncategorized" as the category.

Text: {{input_text}}

Current date: {{current_date}}

Format your response as follows:
DATE: ...
EXPENSE: ...
INCOME: ...
CATEGORY: ...
DESCRIPTION: ...
FEEDBACK: ...
    """

    current_date = datetime.now().strftime('%Y-%m-%d')
    formatted_prompt = transaction_prompt.format(
        input_text=text,
        current_date=current_date
    )

    response = llm.invoke(formatted_prompt)
    return response

# ---- 4. LLM RESPONSE PARSING ---- #
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
    expinc_match = re.search(r"EXPENSE/INCOME:\s*([\d.]+)", response, re.IGNORECASE)

    if expense_match:
        expense = float(expense_match.group(1))
        income = 0.0
    elif income_match:
        expense = 0.0
        income = float(income_match.group(1))
    elif expinc_match:
        expense = float(expinc_match.group(1))
        income = 0.0  #  default this to expense!
    else:
        expense = 0.0
        income = 0.0

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

# ---- 5. GET CATEGORY ID ---- #
def get_category_id(category_name: str, supabase):
    if not category_name:
        return None
    cat_response = supabase.table("categories").select("category_id").eq("category_name", category_name).execute()
    cat_data = cat_response.data
    if cat_data:
        return cat_data[0]["category_id"]
    else:
        return None

# ---- 6. ADD TRANSACTION ---- #
def add_transaction_from_llm(llm_response, user_id, supabase):
    extracted = parse_llm_response(llm_response)
    description_valid = extracted["description"] not in (None, "", "No Description")
    amount_valid = (extracted["expense"] > 0 or extracted["income"] > 0)
    if not description_valid or not amount_valid:
        return "❌ Cannot add transaction: missing information."

    # Strict: Only allow user's actual categories (or Uncategorized)
    user_cats = get_cached_user_categories(user_id, supabase)
    allowed_expense = set(user_cats["expense"])
    allowed_income = set(user_cats["income"])
    if extracted["expense"] > 0:  # It's an expense
        if extracted["category"] not in allowed_expense:
            extracted["category"] = "Uncategorized"
    elif extracted["income"] > 0:  # It's an income
        if extracted["category"] not in allowed_income:
            extracted["category"] = "Uncategorized"

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

# ---- 7. DEMO / TEST ---- #
if __name__ == "__main__":
    test_uid = DEFAULT_USER_ID
    print(get_cached_user_categories(test_uid, supabase))

    test_inputs = [
        "Had dinner for 150 EGP last night",
        "Milk 50",
        "work on tasks got 500",
        "got 500",
        "SON 200",
        "catii eat 200",
        "little shirt 200",
        "Received salary 8000 EGP today",
        "Dinner today",
        "50 today",
        "Dibers 300",
        "Diapers 300"
    ]

    for user_input in test_inputs:
        print("\n-----------------------------")
        print("Input:", user_input)
        llm_response = process_transaction_with_llm(user_input, user_id=test_uid, supabase=supabase)
        print("LLM Output:\n", llm_response)
        result = add_transaction_from_llm(llm_response, user_id=test_uid, supabase=supabase)
        print(result)