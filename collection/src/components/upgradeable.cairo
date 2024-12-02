use starknet::ClassHash;

#[starknet::interface]
trait IUpgradeable<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

/// # Upgradeable Component
///
/// The Upgradeable component provides a mechanism to make a contract upgradeable.
#[starknet::component]
mod UpgradeableComponent {
    use starknet::ClassHash;
    use starknet::SyscallResultTrait;
    use tcg_collection::components::ownable::OwnableComponent;
    use tcg_collection::components::ownable::OwnableComponent::OwnableInternalImpl;

    #[storage]
    struct Storage {}
    
    #[derive(Drop, PartialEq, starknet::Event)]
    struct Upgraded {
        class_hash: ClassHash
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        Upgraded: Upgraded
    }

    mod Errors {
        const INVALID_CLASS: felt252 = 'Class hash cannot be zero';
    }

    #[embeddable_as(UpgradeableImpl)]
    pub impl Upgradeable<
        TContractState,
        +HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>, +Drop<TContractState>
    > of super::IUpgradeable<ComponentState<TContractState>> {
        fn upgrade(ref self: ComponentState<TContractState>, new_class_hash: ClassHash) {
            let ownable_component = get_dep_component!(@self, Ownable);
            ownable_component._assert_only_owner();
            self._upgrade(new_class_hash);
        }
    }

    #[generate_trait]
    impl UpgradeableInternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn _upgrade(ref self: ComponentState<TContractState>, new_class_hash: ClassHash) {
            assert(!new_class_hash.is_zero(), Errors::INVALID_CLASS);
            starknet::replace_class_syscall(new_class_hash).unwrap_syscall();
            self.emit(Upgraded { class_hash: new_class_hash });
        }
    }
}
