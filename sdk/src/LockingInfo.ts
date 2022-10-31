import {ITokenId} from "./CollectionInfo";

export interface ITokenLocks {
    locking: ITokenId[];
}

export interface ITokenLocksData {
    locking_tokens: string[];
    locking_token_address: {
        handle: string;
    };
    locking_time: {
        handle: string;
    };
}
