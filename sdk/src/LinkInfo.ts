import {ITokenId} from "./CollectionInfo";

export interface ILinkInfo {
    token_accessory_table: {
        handle: string;
    };
    token_weapon_table: {
        handle: string;
    };
    token_link_events_table: {
        handle: string;
    };
}

export interface LinkEvents {
    counter: string;
    guid: {
        id: {
            addr: string;
            creation_num: string;
        };
    };
}

export interface LinkEvent {
    guid: {
        creation_number: string;
        account_address: string;
    };
    sequence_number: string;
    type: string;
    version: string;
    data: LinkHistoryItem;
}

export interface LinkHistoryItem {
    operator: string;
    type: string;
    time: string;
    token_id: ITokenId;
    change_token_id: ITokenId;
    name: string;
}
