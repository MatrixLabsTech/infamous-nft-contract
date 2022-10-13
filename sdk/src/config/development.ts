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
        moduleAddress: "0x5228bff9b6561aaee0668df4df14156b7c12a38b98ef22fb5cc13032274c2d5d",
        infamousBackendAuth: "infamous_backend_auth",
        infamousManagerCap: "infamous_manager_cap",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousNft: "infamous_nft",
        infamousWeaponWear: "infamous_weapon_wear",
        infamousStake: "infamous_stake",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousBackendOpenBox: "infamous_backend_open_box",
    },
    devnet: {
        moduleAddress: "0x5228bff9b6561aaee0668df4df14156b7c12a38b98ef22fb5cc13032274c2d5d",
        infamousCommon: "infamous_common",
        infamousBackendAuth: "infamous_backend_auth",
        infamousManagerCap: "infamous_manager_cap",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousNft: "infamous_nft",
        infamousWeaponWear: "infamous_weapon_wear",
        infamousStake: "infamous_stake",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousBackendOpenBox: "infamous_backend_open_box",
    },
};
