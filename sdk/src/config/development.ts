export const collectionResource = `0x3::token::Collections`;
export const tokenStoreResource = `0x3::token::TokenStore`;
export const infamousCollectionName = "InfamousNFT";
export const weaponCollectionName = "InfamousEquipmentNFT";

export interface IDeployment {
    moduleAddress: string;
    infamousBackendAuth: string;
    infamousManagerCap: string;
    infamousWeaponNft: string;
    infamousNft: string;
    infamousWeaponWear: string;
    infamousWeaponStatus: string;
    infamousStake: string;
    infamousUpgradeLevel: string;
    infamousBackendOpenBox: string;
    infamousBackendTokenWeaponAirdrop: string;
}

export const deployment = {
    testnet: {
        moduleAddress: "0xeae7a058d7511286722c8cf47a3f288c918f5359b9c3aeeb56cb27d170584f89",
        infamousBackendAuth: "infamous_backend_auth",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponAirdrop: "infamous_backend_token_weapon_airdrop",
        infamousCommon: "infamous_common",
        infamousManagerCap: "infamous_manager_cap",
        infamousNft: "infamous_nft",
        infamousStake: "infamous_stake",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousWeaponStatus: "infamous_weapon_status",
        infamousWeaponWear: "infamous_weapon_wear",
    },
    devnet: {
        moduleAddress: "0xeae7a058d7511286722c8cf47a3f288c918f5359b9c3aeeb56cb27d170584f89",
        infamousBackendAuth: "infamous_backend_auth",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponAirdrop: "infamous_backend_token_weapon_airdrop",
        infamousCommon: "infamous_common",
        infamousManagerCap: "infamous_manager_cap",
        infamousNft: "infamous_nft",
        infamousStake: "infamous_stake",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousWeaponStatus: "infamous_weapon_status",
        infamousWeaponWear: "infamous_weapon_wear",
    },
};
