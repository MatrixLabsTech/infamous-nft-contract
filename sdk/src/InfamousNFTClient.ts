import {CollectionInfo, ILockingTime, ITokenId, TokenData} from "./CollectionInfo";
import {WearWeaponEvents, WearWeaponHistoryItem} from "./WearWeaponInfo";

export interface ITransaction {
    type: string;
    function: string;
    arguments: any[];
    type_arguments: any[];
}
export interface PaginationArgs {
    start?: number;
    limit?: number;
}

// Failed to deserialize table item retrieved from DB:
// StructTag StructTag { address: 0000000000000000000000000000000000000000000000000000000000000001,
//     module: Identifier("table"), name: Identifier("Table"), type_params: [] } cannot be resolved:
//     PartialVMError { major_status: UNKNOWN_INVARIANT_VIOLATION_ERROR, sub_status: None, message: Some("fat type substitution failed: index out of bounds -- len 0 got 0"), exec_state: None, indices: [], offsets: [] }
export interface InfamousNFTClient {
    // package mint trans
    mintTransaction(count: string): ITransaction;
    lockTransaction(tokenName: string): ITransaction;
    unlockTransaction(tokenName: string): ITransaction;
    upgradeTransaction(tokenName: string): ITransaction;
    wearWeaponTransaction(tokenName: string, weaponName: string): ITransaction;

    // infamous collection info
    collectionInfo(): Promise<CollectionInfo>;

    resolveTokenId(tokenName: string): Promise<ITokenId>;
    resolveWeaponTokenId(tokenName: string): Promise<ITokenId>;
    isTokenOwner(addr: string, tokenId: ITokenId): Promise<boolean>;

    tokenMintTime(tokenId: ITokenId): Promise<string | undefined>;

    // token owned
    tokenOwned(addr: string): Promise<TokenData[]>;

    tokenIdsOwned(addr: string): Promise<ITokenId[]>;

    tokenData(tokenId: ITokenId): Promise<TokenData | undefined>;

    weaponIdsOwned(addr: string): Promise<ITokenId[]>;

    weaponData(weaponTokenName: string): Promise<TokenData | undefined>;

    wearWeaponTotal(tokenId: ITokenId): Promise<WearWeaponEvents | undefined>;
    wearWeaponPage(events: WearWeaponEvents, query?: PaginationArgs): Promise<WearWeaponHistoryItem[]>;

    tokenLocked(addr: string): Promise<ITokenId[]>;

    tokenLockData(tokenId: ITokenId): Promise<ILockingTime | undefined>;

    tokenPerMinted(addr: string): Promise<number>;

    // token level
    tokenLevel(tokenId: ITokenId): Promise<number>;
    // token reveled
    tokenIsReveled(tokenId: ITokenId): Promise<boolean>;

    tokenAirdroped(level: number, tokenId: ITokenId): Promise<ITokenId | undefined>;

    tokenWearedWeapon(tokenId: ITokenId): Promise<ITokenId | undefined>;
}
