import {ITokenId} from "./CollectionInfo";

export interface IWearWeaponInfo {
    token_weapon_table: {
        handle: string;
    };
    token_wear_events_table: {
        handle: string;
    };
}

export interface WearWeaponEvents {
    counter: string;
    guid: {
        id: {
            addr: string;
            creation_num: string;
        };
    };
}

export interface WearWeaponEvent {
    guid: {
        creation_number: string;
        account_address: string;
    };
    sequence_number: string;
    type: string;
    version: string;
    data: WearWeaponHistoryItem;
}

export interface WearWeaponHistoryItem {
    operator: string;
    time: string;
    token_id: ITokenId;
    weapon_name: string;
    weapon_token_id: ITokenId;
}
