module protocol::borrow {
  
  use std::type_name::{Self, TypeName};
  use sui::coin;
  use sui::transfer;
  use sui::event::emit;
  use sui::tx_context::{Self ,TxContext};
  use sui::object::{Self, ID};
  use time::timestamp::{Self ,TimeStamp};
  use protocol::position::{Self, Position};
  use protocol::bank::{Self, Bank};
  use protocol::borrow_withdraw_evaluator;
  use protocol::coin_decimals_registry::CoinDecimalsRegistry;
  
  const EBorrowTooMuch: u64 = 0;
  
  struct BorrowEvent has copy, drop {
    borrower: address,
    position: ID,
    asset: TypeName,
    amount: u64,
    time: u64,
  }
  
  public entry fun borrow<T>(
    position: &mut Position,
    bank: &mut Bank,
    coinDecimalsRegistry: &CoinDecimalsRegistry,
    timeOracle: &TimeStamp,
    borrowAmount: u64,
    ctx: &mut TxContext,
  ) {
    let now = timestamp::timestamp(timeOracle);
    // Always update bank state first
    // Because interest need to be accrued first before other operations
    let borrowedBalance = bank::handle_borrow<T>(bank, borrowAmount, now);
    
    // accure interests for position
    position::accrue_interests(position, bank);
  
    // calc the maximum borrow amount
    // If borrow too much, abort
    let maxBorrowAmount = borrow_withdraw_evaluator::max_borrow_amount<T>(position, bank, coinDecimalsRegistry);
    assert!(borrowAmount <= maxBorrowAmount, EBorrowTooMuch);
    
    // increase the debt for position
    let coinType = type_name::get<T>();
    position::increase_debt(position, coinType, borrowAmount);
    
    // lend the coin to user from bank
    transfer::transfer(
      coin::from_balance(borrowedBalance, ctx),
      tx_context::sender(ctx),
    );
    
    emit(BorrowEvent {
      borrower: tx_context::sender(ctx),
      position: object::id(position),
      asset: coinType,
      amount: borrowAmount,
      time: now,
    })
  }
}
