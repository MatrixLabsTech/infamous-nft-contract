export const collectionResource = `0x3::token::Collections`;
export const tokenStoreResource = `0x3::token::TokenStore`;
export const infamousCollectionName = "InfamousNFT";
export const weaponCollectionName = "InfamousWeaponNFT";
export const accessoryCollectionName = "InfamousAccessoryNFT";

export const block = "369711010";
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
        moduleAddress: "0x5b23f755ff169f8f9ca543e92b3a7a1bd4014629ff8be5aa0204d63e60d040b7",
        managerAddress: "0xd01428b966469ac8db8ea0a342f85dd6ca862c543e6df169b726ed33970bc8d7",
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
        moduleAddress: "0x5b23f755ff169f8f9ca543e92b3a7a1bd4014629ff8be5aa0204d63e60d040b7",
        managerAddress: "0xc14a34d810ecaa7e29979babfa49394430339b18d6214d039c8c17f05ab947cd",
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
