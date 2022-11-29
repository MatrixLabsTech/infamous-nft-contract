export const collectionResource = `0x3::token::Collections`;
export const tokenStoreResource = `0x3::token::TokenStore`;
export const infamousCollectionName = "InfamousNFT";
export const weaponCollectionName = "InfamousWeaponNFT";
export const accessoryCollectionName = "InfamousAccessoryNFT";

export const block = "368788391";
export interface IDeployment {
    moduleAddress: string;
    managerAddress: string;
    infamousBackendAuth: string;
    infamousManagerCap: string;
    infamousWeaponNft: string;
    infamousNft: string;
    infamousWeaponWear: string;
    infamousLinkStatus: string;
    infamousLock: string;
    infamousUpgradeLevel: string;
    infamousBackendOpenBox: string;
    infamousBackendTokenWeaponOpenBox: string;
    infamousBackendTokenAccessoryOpenBox: string;
    infamousChangeAccessory: string;
}

export const deployment = {
    testnet: {
        moduleAddress: "0x0053955eeb3da4043393cae4b8e0d708c04d67ef6991aa5187e3fd76c23086ff",
        managerAddress: "0x5c493ed5e7c152913fd95ead382639b1ec866f783cb844f610c0be9aceed61aa",
        infamousBackendAuth: "infamous_backend_auth",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponOpenBox: "infamous_backend_token_weapon_open_box",
        infamousBackendTokenAccessoryOpenBox: "infamous_backend_token_accessory_open_box",
        infamousCommon: "infamous_common",
        infamousManagerCap: "infamous_manager_cap",
        infamousAccessoryNft: "infamous_accessory_nft",
        infamousNft: "infamous_nft",
        infamousLock: "infamous_lock",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousLinkStatus: "infamous_link_status",
        infamousWeaponWear: "infamous_weapon_wear",
        infamousChangeAccessory: "infamous_change_accesory",
    },
    devnet: {
        moduleAddress: "0x0053955eeb3da4043393cae4b8e0d708c04d67ef6991aa5187e3fd76c23086ff",
        managerAddress: "0xe1f557fa40e388ce570920385dab2f96db811070496f901e88466f137d613ef3",
        infamousBackendAuth: "infamous_backend_auth",
        infamousBackendOpenBox: "infamous_backend_open_box",
        infamousBackendTokenWeaponOpenBox: "infamous_backend_token_weapon_open_box",
        infamousBackendTokenAccessoryOpenBox: "infamous_backend_token_accessory_open_box",
        infamousCommon: "infamous_common",
        infamousManagerCap: "infamous_manager_cap",
        infamousAccessoryNft: "infamous_accessory_nft",
        infamousNft: "infamous_nft",
        infamousLock: "infamous_lock",
        infamousUpgradeLevel: "infamous_upgrade_level",
        infamousWeaponNft: "infamous_weapon_nft",
        infamousLinkStatus: "infamous_link_status",
        infamousWeaponWear: "infamous_weapon_wear",
        infamousChangeAccessory: "infamous_change_accesory",
    },
};
