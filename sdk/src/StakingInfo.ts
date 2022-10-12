//   struct TokenStakes has key {
//         staking: vector<TokenId>,
//     }

import {ITokenId} from "./CollectionInfo";

export interface ITokenStakes {
    staking: ITokenId[];
}

export interface ITokenStakesData {
    staking_tokens: string[];
    staking_token_address: {
        handle: string;
    };
    staking_time: {
        handle: string;
    };
}
