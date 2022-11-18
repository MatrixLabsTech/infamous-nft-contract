export const collectionResource = `0x3::token::Collections`;
export const tokenStoreResource = `0x3::token::TokenStore`;
export const infamousCollectionName = "InfamousNFT";
export const weaponCollectionName = "InfamousEquipmentNFT";

export const block = "12429489";
export interface IDeployment {
    moduleAddress: string;
    infamousBackendAuth: string;
    infamousManagerCap: string;
    infamousWeaponNft: string;
    infamousNft: string;
    infamousWeaponWear: string;
    infamousWeaponStatus: string;
    infamousLock: string;
    infamousUpgradeLevel: string;
    infamousBackendOpenBox: string;
    infamousBackendTokenWeaponOpenBox: string;
    infamousBackendTokenWeaponAirdrop: string;
}

export const deployment = {
    testnet: {
        moduleAddress: "0xbfd09ab90edcad8de437f23ed5cf070a6ef48eef5f178a898cebd0e4df3d8321",
        infamousBackendAuth: "infamous_backend_auth",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponAirdrop: "infamous_backend_token_weapon_airdrop_box",
        infamousBackendTokenWeaponOpenBox: "infamous_backend_token_weapon_open_box",
        infamousCommon: "infamous_common",
        infamousManagerCap: "infamous_manager_cap",
        infamousNft: "infamous_nft",
        infamousLock: "infamous_lock",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousWeaponStatus: "infamous_weapon_status",
        infamousWeaponWear: "infamous_weapon_wear",
    },
    devnet: {
        moduleAddress: "0xbfd09ab90edcad8de437f23ed5cf070a6ef48eef5f178a898cebd0e4df3d8321",
        infamousBackendAuth: "infamous_backend_auth",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponAirdrop: "infamous_backend_token_weapon_airdrop_box",
        infamousBackendTokenWeaponOpenBox: "infamous_backend_token_weapon_open_box",
        infamousCommon: "infamous_common",
        infamousManagerCap: "infamous_manager_cap",
        infamousNft: "infamous_nft",
        infamousLock: "infamous_lock",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousWeaponStatus: "infamous_weapon_status",
        infamousWeaponWear: "infamous_weapon_wear",
    },
};
