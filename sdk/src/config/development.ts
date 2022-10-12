export const collectionResource = `0x3::token::Collections`;
export const tokenStoreResource = `0x3::token::TokenStore`;
export const collectionName = "InfamousNFT";

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
        moduleAddress: "0x77f881b75f0ef9913873986b2d3f38bd8d2981654f314f57207fccd859f2b68e",
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
        moduleAddress: "0x77f881b75f0ef9913873986b2d3f38bd8d2981654f314f57207fccd859f2b68e",
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
