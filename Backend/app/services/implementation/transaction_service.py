from typing import List, Optional
from uuid import UUID, uuid4
from datetime import datetime

from app.core.supabase import get_supabase
from app.services.interfaces.transaction_service import ITransactionService
from app.models.transaction_dto import CreateTransactionRequest, TransactionResponse
from app.domain.transaction import Transaction, TransactionType
from app.infrastructure.interfaces.transaction_repository import ITransactionRepository
from app.core.Add_Trans import (
    process_transaction_with_llm,
    parse_llm_response,
    get_category_id,
)


class TransactionService(ITransactionService):
    def __init__(self, transaction_repository: ITransactionRepository):
        self.transaction_repository = transaction_repository

    def create_transaction(
        self, data: CreateTransactionRequest
    ) -> Optional[TransactionResponse]:

        # Step 1: Get LLM raw response and parse
        raw_response = process_transaction_with_llm(data.input_text)
        parsed = parse_llm_response(raw_response)

        # Step 2: Validate transaction_type
        transaction_type_str = parsed.get("transaction_type")
        if not transaction_type_str:
            raise ValueError("Missing transaction_type from LLM response")

        try:
            # Handle case-insensitive enum value
            transaction_type = TransactionType(transaction_type_str.capitalize())
        except ValueError:
            raise ValueError(f"Invalid transaction_type: {transaction_type_str}")

        # Step 3: Get category ID using Supabase
        category_id = get_category_id(parsed["category"], get_supabase())

        # Step 4: Create domain model
        transaction = Transaction(
            transaction_id=uuid4(),
            user_id=data.user_id,
            category_id=category_id,
            description=parsed["description"],
            created_at=datetime.strptime(parsed["created_at"], "%Y-%m-%d %H:%M:%S+00"),
            amount=parsed["amount"],
            transaction_type=transaction_type,
        )

        # Step 5: Persist and return
        response = self.transaction_repository.create_transaction(transaction)

        return TransactionResponse(
            transaction_id=response.transaction_id,
            user_id=response.user_id,
            category_id=response.category_id,
            description=response.description,
            created_at=response.created_at,
            amount=response.amount,
            transaction_type=response.transaction_type,
            feedback=parsed["feedback"],
        )

    def get_transaction_by_id(
        self, transaction_id: UUID
    ) -> Optional[TransactionResponse]:
        tx = self.transaction_repository.get_transaction_by_id(transaction_id)
        return TransactionResponse(**tx.__dict__) if tx else None

    def get_transactions_by_user_id(self, user_id: UUID) -> List[TransactionResponse]:
        txs = self.transaction_repository.get_transactions_by_user_id(user_id)
        return [TransactionResponse(**tx.__dict__) for tx in txs]

    def get_all_transactions(self) -> List[TransactionResponse]:
        txs = self.transaction_repository.get_all_transactions()
        return [TransactionResponse(**tx.__dict__) for tx in txs]

    def update_transaction(
        self, transaction: Transaction
    ) -> Optional[TransactionResponse]:
        updated = self.transaction_repository.update_transaction(transaction)
        return TransactionResponse(**updated.__dict__) if updated else None

    def delete_transaction(self, transaction_id: UUID) -> bool:
        return self.transaction_repository.delete_transaction(transaction_id)

    def get_transactions_by_category_id(
        self, category_id: UUID
    ) -> List[TransactionResponse]:
        txs = self.transaction_repository.get_transactions_by_category_id(category_id)
        return [TransactionResponse(**tx.__dict__) for tx in txs]
