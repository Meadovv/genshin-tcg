use tcg_collection::models::mint_info::MintInfo;
#[starknet::interface]
pub trait ICollection<TContractState> {
    fn mint(ref self: TContractState, mint_info: MintInfo, signature_r: felt252, signature_s: felt252) -> u256;
}

#[starknet::contract]
mod Collection {

    use starknet::ContractAddress;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::introspection::src5::SRC5Component;
    use tcg_collection::components::{
        ownable::OwnableComponent,
        upgradeable::UpgradeableComponent,
    };
    use tcg_collection::models::mint_info::{Mint, MintInfo, MintInfoTrait};

    component!(path: ERC721Component, storage: ERC721Storage, event: ERC721Event);
    component!(path: SRC5Component, storage: SRC5Storage, event: SRC5Event);
    component!(path: OwnableComponent, storage: OwnableStorage, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: UpgradeableStorage, event: UpgradeableEvent);

    // Public functions
    #[abi(embed_v0)]
    impl ERC721Metadata = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly = ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721 = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl Ownable = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl Upgradeable = UpgradeableComponent::UpgradeableImpl<ContractState>;

    // Internal functions
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::OwnableInternalImpl<ContractState>;

    mod Errors {

    }

    #[storage]
    struct Storage {
        token_id: u256,
        total_supply: u256,
        uri_path_1: felt252,
        uri_path_2: felt252,
        uri_path_3: felt252,
        uri_path_4: felt252,
        uri_path_5: felt252,
        #[substorage(v0)]
        ERC721Storage: ERC721Component::Storage,
        #[substorage(v0)]
        SRC5Storage: SRC5Component::Storage,
        #[substorage(v0)]
        OwnableStorage: OwnableComponent::Storage,
        #[substorage(v0)]
        UpgradeableStorage: UpgradeableComponent::Storage
    }

    #[derive(Drop, starknet::Event)]
    struct NFTMinted {
        owner: ContractAddress,
        token_id: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NFTMinted: NFTMinted,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    const OWNER_ADDRESS: felt252 =
        0x05fE8F79516C123e8556eA96bF87a97E7b1eB5AbdBE4dbCD993f3FB9A6F24A66;

    #[constructor]
    fn constructor(ref self: ContractState) {
        let name: ByteArray = "TCG Character Collection";
        let symbol: ByteArray = "TCG";
        let base_uri: ByteArray = "https://literally-daring-anemone.ngrok-free.app/assets/metadata";
        self.ERC721Storage.initializer(name, symbol, base_uri); 
        self.OwnableStorage.initializer(
            OWNER_ADDRESS.try_into().unwrap()
        );
    }

    #[abi(embed_v0)]
    impl ICollectionImpl of super::ICollection<ContractState> {
        fn mint(ref self: ContractState, mint_info: MintInfo, signature_r: felt252, signature_s: felt252) -> u256 {
            let mint = MintInfoTrait::verify_signature(mint_info, signature_r, signature_s);
            self.ERC721Storage._mint(mint.owner, mint.token_id);
            mint.token_id
        }
    }
}