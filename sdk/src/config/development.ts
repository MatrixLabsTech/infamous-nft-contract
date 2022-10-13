export const collectionResource = `0x3::token::Collections`;
export const tokenStoreResource = `0x3::token::TokenStore`;
export const infamousCollectionName = "InfamousNFT";
export const weaponCollectionName = "InfamousWeaponNFT";

export interface IDeployment {
    moduleAddress: string;
    infamousBackendAuth: string;
    infamousManagerCap: string;
    infamousWeaponNft: string;
    infamousNft: string;
    infamousWeaponWear: string;
    infamousStake: string;
    infamousUpgradeLevel: string;
    infamousBackendOpenBox: string;
}

export const deployment = {
    testnet: {
        moduleAddress: "0x0a76b8e3a846682fe6da566e5879a1d06d4c9d41cdf6db21dba46b5852e9e5e9",
        infamousBackendAuth: "infamous_backend_auth",
        infamousManagerCap: "infamous_manager_cap",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousNft: "infamous_nft",
        infamousWeaponWear: "infamous_weapon_wear",
        infamousStake: "infamous_stake",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponAirdrop: "infamous_backend_token_weapon_airdrop",
    },
    devnet: {
        moduleAddress: "0x0a76b8e3a846682fe6da566e5879a1d06d4c9d41cdf6db21dba46b5852e9e5e9",
        infamousCommon: "infamous_common",
        infamousBackendAuth: "infamous_backend_auth",
        infamousManagerCap: "infamous_manager_cap",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousNft: "infamous_nft",
        infamousWeaponWear: "infamous_weapon_wear",
        infamousStake: "infamous_stake",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponAirdrop: "infamous_backend_token_weapon_airdrop",
    },
};
