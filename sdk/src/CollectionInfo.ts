export interface ITokenId {
    property_version: string;
    token_data_id: {
        collection: string;
        creator: string;
        name: string;
    };
}

export interface ICollectionStatusInfo {
    counter: string;
    per_minted_table: {
        handle: string;
    };
    token_mint_time_table: {
        handle: string;
    };
    token_minted_events: {
        counter: string;
        guid: {
            id: {
                addr: string;
                creation_num: string;
            };
        };
    };
}

export interface Collections {
    type: "0x3::token::Collections";
    data: {
        collection_data: {
            handle: string;
        };
        create_collection_events: {
            counter: string;
            guid: {
                id: {
                    addr: string;
                    creation_num: string;
                };
            };
        };
        create_token_data_events: {
            counter: string;
            guid: {
                id: {
                    addr: string;
                    creation_num: string;
                };
            };
        };
        mint_token_events: {
            counter: string;
            guid: {
                id: {
                    addr: string;
                    creation_num: string;
                };
            };
        };
        token_data: {
            handle: string;
        };
    };
}

export interface IEvent {
    counter: string;
    guid: {
        id: {
            addr: string;
            creation_num: string;
        };
    };
}

export interface ITokenStore {
    type: "0x3::token::TokenStore";
    data: {
        burn_events: IEvent;
        deposit_events: IEvent;
        direct_transfer: false;
        mutate_token_property_events: IEvent;
        tokens: {
            handle: string;
        };
        withdraw_events: IEvent;
    };
}

export interface Property {
    key: string;
    value: {type: string; value: string};
}

export interface IToken {
    amount: string;
    id: ITokenId;
    token_properties: {
        map: {
            data: Property[];
        };
    };
}

export interface ITokenDataId {
    name: string;
    creator: string;
    collection: string;
}

export interface MutateEvent {
    version: string;
    key: string;
    guid: {
        creation_number: string;
        account_address: string;
    };
    sequence_number: string;
    type: "0x3::token::MutateTokenPropertyMapEvent";
    data: {
        keys: string[];
        new_id: ITokenId;
        old_id: ITokenId;
        types: string[];
        values: string[];
    };
}

export interface TokenEvent {
    version: string;
    key: string;
    guid: {
        creation_number: string;
        account_address: string;
    };
    sequence_number: string;
    type: TokenEventType;
    data: {
        amount: string;
        id: ITokenId;
    };
}

export interface CollectionInfo {
    description: string;
    maximum: string;
    mutability_config: {
        description: boolean;
        maximum: false;
        uri: false;
    };
    name: string;
    supply: string;
    uri: string;
}

export interface PropertyItem {
    key: string;
    value: string;
}

export interface TokenData {
    // Unique name within this creators account for this Token's collection
    collection: string;
    // Describes this Token
    description: string;
    // The name of this Token
    name: string;
    // Optional maximum number of this type of Token.
    maximum?: string;
    // Total number of this type of Token
    supply: string;
    /// URL for additional information / media
    uri: string;
    properties: PropertyItem[];
}

export interface ILockingTime {
    start: string;
    lock_time_used: string;
}

export interface ITokenData {
    default_properties: {map: {data: Property[]}};
    description: string;
    largest_property_version: string;
    maximum: string;
    name: string;
    royalty: {
        payee_address: string;
        royalty_points_denominator: string;
        royalty_points_numerator: string;
    };
    supply: string;
    uri: string;
}

export type TokenEventType = "0x3::token::DepositEvent" | "0x3::token::BurnEvent" | "0x3::token::WithdrawEvent";
export interface IEventItem {
    tokenId: ITokenId;
    type: TokenEventType;
    version: string;
}

export interface MoveResource {
    data: any;
    type: string;
}
