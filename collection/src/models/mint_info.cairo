use starknet::ContractAddress;
use core::option::OptionTrait;
use core::hash::{HashStateTrait, HashStateExTrait, Hash};
use pedersen::PedersenTrait;
use ecdsa::check_ecdsa_signature;
use tcg_collection::constants::{ADDRESS_SIGN, PUBLIC_KEY_SIGN};

const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");
const MINT_INFO_TYPE_HASH: felt252 =
    selector!("MintInfo(owner:felt,token_id:felt,nonce:felt)");

#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct StarknetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252,
}

#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct Mint {
    owner: ContractAddress,
    token_id: u256,
    nonce: u64
}

#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct MintInfo {
    owner: felt252,
    token_id: felt252,
    nonce: felt252
}

trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

trait MintInfoTrait {
    fn verify_signature(mint_info: MintInfo, signature_r: felt252, signature_s: felt252) -> Mint;
}

impl MintInfoImpl of MintInfoTrait {
    fn verify_signature(mint_info: MintInfo, signature_r: felt252, signature_s: felt252) -> Mint {
        let message_hash = mint_info.get_message_hash();
        assert(
            check_ecdsa_signature(
                message_hash,
                PUBLIC_KEY_SIGN,
                signature_r,
                signature_s
            ),
            'Invalid signature'
        );
        Mint {
            owner: mint_info.owner.try_into().unwrap(),
            token_id: mint_info.token_id.try_into().unwrap(),
            nonce: mint_info.nonce.try_into().unwrap()
        }
    }
}

impl OffchainMessageHashMintInfo of IOffchainMessageHash<MintInfo> {
    fn get_message_hash(self: @MintInfo) -> felt252 {
        let domain = StarknetDomain { name: 'TCG', version: 1, chain_id: 'SN_MAIN' };
        let address_sign: ContractAddress = ADDRESS_SIGN.try_into().unwrap();
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with('StarkNet Message');
        hashState = hashState.update_with(domain.hash_struct());
        hashState = hashState.update_with(address_sign);
        hashState = hashState.update_with(self.hash_struct());
        hashState = hashState.update_with(4);
        hashState.finalize()
    }
}

impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
    fn hash_struct(self: @StarknetDomain) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(STARKNET_DOMAIN_TYPE_HASH);
        hashState = hashState.update_with(*self);
        hashState = hashState.update_with(4);
        hashState.finalize()
    }
}

impl StructHashMintInfo of IStructHash<MintInfo> {
    fn hash_struct(self: @MintInfo) -> felt252 {
        let mut hashState = PedersenTrait::new(0);
        hashState = hashState.update_with(MINT_INFO_TYPE_HASH);
        hashState = hashState.update_with(*self);
        hashState = hashState.update_with(4);
        hashState.finalize()
    }
}
