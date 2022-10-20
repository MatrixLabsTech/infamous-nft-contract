import {ITokenId} from "./CollectionInfo";

export interface IWearWeaponInfo {
    token_weapon_table: {
        handle: string;
    };
    weapon_wear_events: {
        counter: string;
        guid: {
            id: {
                addr: string;
                creation_num: string;
            };
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
    weapon_token_id: ITokenId;
}
