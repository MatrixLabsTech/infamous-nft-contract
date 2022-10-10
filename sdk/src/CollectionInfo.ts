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

export interface ITokenStore {
    type: "0x3::token::TokenStore";
    data: {
        burn_events: {
            counter: string;
            guid: {
                id: {
                    addr: string;
                    creation_num: string;
                };
            };
        };
        deposit_events: {
            counter: string;
            guid: {
                id: {
                    addr: string;
                    creation_num: string;
                };
            };
        };
        direct_transfer: false;
        mutate_token_property_events: {
            counter: string;
            guid: {
                id: {
                    addr: string;
                    creation_num: string;
                };
            };
        };
        tokens: {
            handle: string;
        };
        withdraw_events: {
            counter: string;
            guid: {
                id: {
                    addr: string;
                    creation_num: string;
                };
            };
        };
    };
}

export interface Property {
    key: string;
    value: {type: string; value: string};
}

export interface IToken {
    amount: string;
    id: {
        property_version: string;
        token_data_id: {
            collection: string;
            creator: string;
            name: string;
        };
    };
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

export interface TokenStakes {
    type: string;
    data: {
        staking: ITokenDataId[];
        staking_time: {
            inner: {
                handle: string;
            };
            length: string;
        };
    };
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

export interface DepositEvent {
    version: string;
    key: string;
    guid: {
        creation_number: string;
        account_address: string;
    };
    sequence_number: string;
    type: "0x3::token::DepositEvent";
    data: {
        amount: string;
        id: ITokenId;
    };
}
export interface BurnEvent {
    version: string;
    key: string;
    guid: {
        creation_number: string;
        account_address: string;
    };
    sequence_number: string;
    type: "0x3::token::BurnTokenEvent";
    data: {
        amount: string;
        id: ITokenId;
    };
}

export interface WithdrawEvent {
    version: string;
    key: string;
    guid: {
        creation_number: string;
        account_address: string;
    };
    sequence_number: string;
    type: "0x3::token::WithdrawEvent";
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

export interface TokenData {
    // Unique name within this creators account for this Token's collection
    collection: string;
    // Describes this Token
    description: string;
    // The name of this Token
    name: string;
    // Optional maximum number of this type of Token.
    maximum?: number;
    // Total number of this type of Token
    supply: number;
    /// URL for additional information / media
    uri: string;
}
