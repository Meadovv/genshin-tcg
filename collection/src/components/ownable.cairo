use starknet::ContractAddress;

#[starknet::interface]
pub trait IOwnable<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
}

#[starknet::component]
pub mod OwnableComponent {

    use starknet::{ContractAddress, get_caller_address};

    pub mod Errors {
        pub const UNAUTHORIZED: felt252 = 'Not owner';
        pub const ZERO_ADDRESS_OWNER: felt252 = 'Owner cannot be zero';
        pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller cannot be zero';
    }

    #[storage]
    struct Storage {
        pub owner: ContractAddress,
    }

    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub struct OwnershipTransferredEvent {
        pub previous: ContractAddress,
        pub new: ContractAddress
    }


    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        OwnershipTransferredEvent: OwnershipTransferredEvent,
    }

    #[embeddable_as(OwnableImpl)]
    pub impl Ownable<
        TContractState, +HasComponent<TContractState>
    > of super::IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            self._assert_only_owner();
            self._transfer_ownership(new_owner);
        }
    }

    #[generate_trait]
    pub impl OwnableInternalImpl<
        TContractState, +HasComponent<TContractState>
    > of OwnableInternalTrait<TContractState> {
        fn _assert_only_owner(self: @ComponentState<TContractState>) {
            let caller = get_caller_address();
            assert(caller.is_non_zero(), Errors::ZERO_ADDRESS_CALLER);
            assert(caller == self.owner.read(), Errors::UNAUTHORIZED);
        }

        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            assert(owner.is_non_zero(), Errors::ZERO_ADDRESS_OWNER);
            self.owner.write(owner);
        }

        fn _transfer_ownership(ref self: ComponentState<TContractState>, new: ContractAddress) {
            assert(new.is_non_zero(), Errors::ZERO_ADDRESS_OWNER);
            let previous = self.owner.read();
            self.owner.write(new);
            self
                .emit(
                    Event::OwnershipTransferredEvent(OwnershipTransferredEvent { previous, new })
                );
        }
    }
}