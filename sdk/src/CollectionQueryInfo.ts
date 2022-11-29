export interface TokenQueryData {
    name: string;
    collection_name: string;
    creator_address: string;
    property_version: number;
    amount: number;
    current_token_data: {
        default_properties: {
            [key: string]: string;
        };
        metadata_uri: string;
    };
}

export type QueryTokensResult = {data: {current_token_ownerships: TokenQueryData[]}};
