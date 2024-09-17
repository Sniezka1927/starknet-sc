use starknet::ContractAddress;

pub mod ERC20;

#[starknet::interface]
pub trait IEscrow<TContractState> {
    fn is_initialized(self: @TContractState) -> bool;
    fn get_balance(self: @TContractState) -> u256;
    fn deposit(ref self: TContractState, token_address: ContractAddress, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
}

#[starknet::contract]
mod Escrow {
    
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use openzeppelin_token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};

    #[storage]
    struct Storage {
        is_initialized: bool,
        balances: Map<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.is_initialized.write(true);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of super::IEscrow<ContractState> {
        fn is_initialized(self: @ContractState) -> bool {
            self.is_initialized.read()
        }

        fn get_balance(self: @ContractState) -> u256 {
            let caller = get_caller_address();
            self.balances.read(caller)
        }

        fn deposit(ref self: ContractState, token_address: ContractAddress, amount: u256) {
            assert(amount != 0, 'Amount cannot be 0');
            let caller = get_caller_address();
            let current_amount = self.balances.read(caller);
            self.balances.write(caller, current_amount + amount);
            let token = ERC20ABIDispatcher { contract_address: token_address };
            let allowance = token.allowance(caller, get_contract_address());
            println!("{:?}", allowance);
            println!("{:?}", caller);
            println!("{:?}", get_contract_address());
            token.transfer_from(caller, get_contract_address(), amount);
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            assert(amount != 0, 'Amount cannot be 0');
            let caller = get_caller_address();
            let current_amount = self.balances.read(caller);
            assert(current_amount >= amount, 'Insufficient balance');
            self.balances.write(caller, current_amount - amount);
        }
    }
}
