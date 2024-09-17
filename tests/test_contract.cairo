use starknet::ContractAddress;
use starknet::contract_address_const;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use snforge_std::start_cheat_caller_address_global;
use openzeppelin_token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use escrow::IEscrowDispatcher;
use escrow::IEscrowDispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn deploy_erc20(address: felt252) -> ContractAddress {
    let contract = declare("MyToken").unwrap().contract_class();
    let constructor_args = array![1000000, 0, address];
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

#[test]
fn test_constructor() {
    let contract_address = deploy_contract("Escrow");

    let dispatcher = IEscrowDispatcher { contract_address };

    let is_initialized = dispatcher.is_initialized();
    assert(is_initialized == true, 'Contract is not initialized');
}

#[test]
fn test_mint() {
    let caller = contract_address_const::<0x123>();
    let erc20_address = deploy_erc20(0x123);
    
    start_cheat_caller_address_global(caller);
    
    let contract_address = deploy_contract("Escrow");

    let escrow = IEscrowDispatcher { contract_address };
    let token = ERC20ABIDispatcher { contract_address: erc20_address };

    let amount = 1;
    let approved = 10000000000000000000000000000000000000;
    
    assert(token.balance_of(caller) != 0, 'Zero balance');

    token.approve(escrow.contract_address, approved);

    let allowance = token.allowance(caller, escrow.contract_address);
    assert(allowance == approved, 'Invalid allowance');

    // Throws error
    escrow.deposit(erc20_address, amount);

    let balance_after = escrow.get_balance();
    assert(balance_after == amount, 'Invalid balance');
}

// #[test]
// fn test_burn() {
//     let contract_address = deploy_contract("Escrow");
//     // let erc20_address = deploy_erc20();

//     let dispatcher = IEscrowDispatcher { contract_address };
//     // let token = ERC20ABIDispatcher { contract_address: erc20_address };

//     let balance_before = dispatcher.get_balance();
//     assert(balance_before == 0, 'Invalid balance');

//     // token.approve(contract_address, 42);
//     dispatcher.deposit(42);

//     let balance_after = dispatcher.get_balance();
//     assert(balance_after == 42, 'Invalid balance');

//     dispatcher.withdraw(22);


//     let balance_after_burn = dispatcher.get_balance();
//     assert(balance_after_burn == 20, 'Invalid balance');
// }
 
#[test]
fn test_erc20_deployment_and_operations() {
    // Deploy the contract
    let contract = declare("MyToken").unwrap().contract_class();
    let constructor_args = array![1000000, 0, 0x123];
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    let token = ERC20ABIDispatcher { contract_address };
    assert(token.name() == "MyToken", 'Invalid name');
    assert(token.symbol() == "MTK", 'Invalid symbol');
    assert(token.totalSupply() == 1000000, 'Invalid total supply');
}

#[test]
fn test_deploy_erc20_util() {
    let erc20_address = deploy_erc20(0x123);
    let token = ERC20ABIDispatcher { contract_address: erc20_address };
    let caller = contract_address_const::<0x123>();
    assert(token.name() == "MyToken", 'Invalid name');
    assert(token.symbol() == "MTK", 'Invalid symbol');
    assert(token.totalSupply() == 1000000, 'Invalid total supply');
    assert(token.total_supply() == 1000000, 'Invalid total supply');
    assert(token.balance_of(caller) == 1000000, 'Invalid balance');
}