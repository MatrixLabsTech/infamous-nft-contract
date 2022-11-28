export interface TokenQueryData {
    token_data_id_hash: string;
    name: string;
    collection_name: string;
    property_version: number;
    amount: number;
    current_token_data: {
        default_properties: {
            [key: string]: string;
        };
        creator_address: string;
        metadata_uri: string;
        name: string;
    };
}

export type CurrentOwnerShips = TokenQueryData[];
