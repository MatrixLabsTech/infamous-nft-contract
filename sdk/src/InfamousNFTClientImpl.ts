import {InfamousNFTClient, ITransaction, PaginationArgs} from "./InfamousNFTClient";

import {
    tokenStoreResource,
    deployment,
    IDeployment,
    infamousCollectionName,
    weaponCollectionName,
    accessoryCollectionName,
} from "./config/development";
import {IManagerAccountCapability} from "./ManagerAccountCapability";
import {
    CollectionInfo,
    ICollectionStatusInfo,
    IEvent,
    IEventItem,
    ILockingTime,
    ITokenData,
    ITokenId,
    ITokenStore,
    MoveResource,
    PropertyItem,
    TokenData,
    TokenEvent,
    TokenEventType,
} from "./CollectionInfo";
import {decodeString, decodeU64, paramToHex} from "./utils/param";
import {AptosClient, TokenClient} from "aptos";
import {
    DEVNET_GRAPHQL_SERVICE,
    DEVNET_REST_SERVICE,
    TESTNET_GRAPHQL_SERVICE,
    TESTNET_REST_SERVICE,
} from "./consts/networks";
import {ITokenLocks, ITokenLocksData} from "./LockingInfo";
import {ILinkInfo, LinkEvents, LinkHistoryItem} from "./LinkInfo";
import {IUpgradeInfo} from "./UpgradeInfo";
import {IOpenBoxStatus} from "./OpenBoxStatus";
import {localCache} from "./utils/localCache";
import {QueryTokensResult, TokenQueryData} from "./CollectionQueryInfo";
import {postData} from "./utils/http";
export enum AptosNetwork {
    Testnet = "Testnet",
    Mainnet = "Mainnet",
    Devnet = "Devnet",
}

export class InfamousNFTClientImpl implements InfamousNFTClient {
    readClient: AptosClient;
    deployment: IDeployment;
    tokenClient: TokenClient;
    manager_addr: string;
    graphyql_url: string;
    constructor(network: AptosNetwork = AptosNetwork.Devnet) {
        if (network === AptosNetwork.Testnet) {
            this.readClient = new AptosClient(TESTNET_REST_SERVICE);
            this.deployment = deployment.testnet;
            this.tokenClient = new TokenClient(this.readClient);
            this.manager_addr = deployment.testnet.managerAddress;
            this.graphyql_url = TESTNET_GRAPHQL_SERVICE;
        } else {
            this.readClient = new AptosClient(DEVNET_REST_SERVICE);
            this.deployment = deployment.devnet;
            this.tokenClient = new TokenClient(this.readClient);
            this.manager_addr = deployment.devnet.managerAddress;
            this.graphyql_url = DEVNET_GRAPHQL_SERVICE;
        }
    }
    mintTransaction(count: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousNft}::mint`,
            arguments: [paramToHex(count, "u64")],
            type_arguments: [],
        };
    }

    lockTransaction(tokenName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousLock}::lock_infamous_nft`,
            arguments: [tokenName],
            type_arguments: [],
        };
    }

    unlockTransaction(tokenName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousLock}::unlock_infamous_nft`,
            arguments: [tokenName],
            type_arguments: [],
        };
    }

    upgradeTransaction(tokenName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousUpgradeLevel}::upgrade`,
            arguments: [tokenName],
            type_arguments: [],
        };
    }

    wearWeaponTransaction(tokenName: string, weaponName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousWeaponWear}::wear_weapon`,
            arguments: [paramToHex(tokenName, "0x1::string::String"), paramToHex(weaponName, "0x1::string::String")],
            type_arguments: [],
        };
    }
    changeAccessoryTransaction(tokenName: string, weaponName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousChangeAccessory}::change_accessory`,
            arguments: [paramToHex(tokenName, "0x1::string::String"), paramToHex(weaponName, "0x1::string::String")],
            type_arguments: [],
        };
    }

    async resolveTokenId(tokenName: string): Promise<ITokenId> {
        const managerAddress = await this.getManagerAddress();
        return {
            property_version: "0",
            token_data_id: {
                collection: infamousCollectionName,
                creator: managerAddress,
                name: tokenName,
            },
        };
    }

    async resolveWeaponTokenId(tokenName: string): Promise<ITokenId> {
        const managerAddress = await this.getManagerAddress();
        return {
            property_version: "0",
            token_data_id: {
                collection: weaponCollectionName,
                creator: managerAddress,
                name: tokenName,
            },
        };
    }

    async queryMyInfamous(addr: string): Promise<TokenQueryData[]> {
        const owned = (await postData(`${this.graphyql_url}`, {
            query: 'query MyInfamousTokens($owner_address: String, $collection_name: String, $creator: String) {\n  current_token_ownerships(\n    where: {collection_name: {_eq: $collection_name}, creator_address: {_eq: $creator}, amount: {_gt: "0"}, owner_address: {_eq: $owner_address}}\n   distinct_on: name\n ) {\n    collection_name\n    creator_address\n    name\n    property_version\n    current_token_data {\n      default_properties\n      metadata_uri\n    }\n  }\n}\n',
            variables: {
                owner_address: addr,
                collection_name: infamousCollectionName,
                creator: this.deployment.managerAddress,
            },
            operationName: "MyInfamousTokens",
        })) as QueryTokensResult;

        return owned.data.current_token_ownerships;
    }

    async queryMyLockedInfamous(addr: string): Promise<TokenQueryData[]> {
        const tokenLockedIds = await this.tokenLocked(addr);
        if (tokenLockedIds.length) {
            const tokenNames = tokenLockedIds.map((tokenId) => tokenId.token_data_id.name);
            const locked = await postData(`${this.graphyql_url}`, {
                query: 'query MyLockedTokens($collection_name: String, $creator: String, $names: [String]) {\n  current_token_ownerships(\n    where: {collection_name: {_eq: $collection_name}, creator_address: {_eq: $creator}, amount: {_gt: "0"}, name: {_in: $names}}\n  distinct_on: name\n ) {\n    collection_name\n    creator_address\n    name\n    property_version\n    current_token_data {\n      default_properties\n      metadata_uri\n    }\n  }\n}\n',
                variables: {
                    collection_name: infamousCollectionName,
                    creator: this.deployment.managerAddress,
                    names: tokenNames,
                },
                operationName: "MyLockedTokens",
            });

            return locked.data.current_token_ownerships;
        }
        return [];
    }

    async queryMyEquipments(addr: string): Promise<TokenQueryData[]> {
        const owned = (await postData(`${this.graphyql_url}`, {
            query: 'query MyEquments($owner_address: String, $collection_name_in: [String], $creator: String) {\n  current_token_ownerships(\n    where: {collection_name: {_in: $collection_name_in}, creator_address: {_eq: $creator}, amount: {_gt: "0"}, owner_address: {_eq: $owner_address}}\n   distinct_on: name\n ) {\n    collection_name\n    creator_address\n    name\n    property_version\n    current_token_data {\n      default_properties\n      metadata_uri\n    }\n  }\n}\n',
            variables: {
                owner_address: addr,
                collection_name_in: [weaponCollectionName, accessoryCollectionName],
                creator: this.deployment.managerAddress,
            },
            operationName: "MyEquments",
        })) as QueryTokensResult;

        return owned.data.current_token_ownerships;
    }

    async isTokenOwner(addr: string, tokenId: ITokenId): Promise<boolean> {
        try {
            const tokenStore = await this.getTokenStoreInfo(addr);
            try {
                const token = await this.tableItem(
                    tokenStore.data.tokens.handle,
                    "0x3::token::TokenId",
                    "0x3::token::Token",
                    tokenId
                );
                if (token) {
                    return true;
                }
            } catch (e) {}
            const lockedTokenId = await this.tokenLocked(addr);
            const eIndex = lockedTokenId.findIndex(
                (lockTokenId) => lockTokenId.token_data_id.name === tokenId.token_data_id.name
            );
            if (eIndex > -1) {
                return true;
            }
        } catch (e) {}
        return false;
    }

    async collectionInfo(): Promise<CollectionInfo> {
        const managerAddress = await this.getManagerAddress();
        const collectionInfo = await this.tokenClient.getCollectionData(managerAddress, infamousCollectionName);
        return collectionInfo;
    }

    async tokenLevel(tokenId: ITokenId): Promise<number> {
        try {
            const upgradeInfo = await this.getUpgradeInfo();
            const info = upgradeInfo.data as IUpgradeInfo;
            const level = await this.tableItem(info.token_level.handle, `0x3::token::TokenId`, `u64`, tokenId);
            return parseInt(level);
        } catch (e) {
            return 1;
        }
    }

    async tokenAirdroped(level: number, tokenId: ITokenId): Promise<ITokenId[] | undefined> {
        try {
            const upgradeInfo = await this.getUpgradeInfo();
            const info = upgradeInfo.data as IUpgradeInfo;
            const token_level_airdrop_table = await this.tableItem(
                info.airdroped.handle,
                `0x3::token::TokenId`,
                `0x1::table::Table<u64, 0x3::token::TokenId>`,
                tokenId
            );

            const airdropTokenIds = await this.tableItem(
                token_level_airdrop_table.handle,
                `u64`,
                `vector<0x3::token::TokenId>`,
                String(level)
            );

            return airdropTokenIds;
        } catch (e) {
            return undefined;
        }
    }

    async tokenIsReveled(tokenId: ITokenId): Promise<boolean> {
        try {
            const openBoxStatus = await this.getOpenBoxStatus();
            const info = openBoxStatus.data as IOpenBoxStatus;
            const reveled = await this.tableItem(info.open_status.handle, `0x3::token::TokenId`, `bool`, tokenId);
            return reveled;
        } catch (e) {
            return false;
        }
    }
    async weaponIsReveled(tokenId: ITokenId): Promise<boolean> {
        try {
            const openBoxStatus = await this.getWeaponOpenBoxStatus();
            const info = openBoxStatus.data as IOpenBoxStatus;
            const reveled = await this.tableItem(info.open_status.handle, `0x3::token::TokenId`, `bool`, tokenId);
            return reveled;
        } catch (e) {
            return false;
        }
    }

    async accessoryIsReveled(tokenId: ITokenId): Promise<boolean> {
        try {
            const openBoxStatus = await this.getAccessoryOpenBoxStatus();
            const info = openBoxStatus.data as IOpenBoxStatus;
            const reveled = await this.tableItem(info.open_status.handle, `0x3::token::TokenId`, `bool`, tokenId);
            return reveled;
        } catch (e) {
            return false;
        }
    }

    async tokenWearedWeapon(tokenId: ITokenId): Promise<ITokenId | undefined> {
        try {
            const tokenLinkInfo = (await this.getTokenLink()).data as ILinkInfo;
            const weapoTokenId = await this.tableItem(
                tokenLinkInfo.token_weapon_table.handle,
                `0x3::token::TokenId`,
                `0x3::token::TokenId`,
                tokenId
            );
            return weapoTokenId;
        } catch (e) {
            return undefined;
        }
    }

    async tokenOwned(addr: string): Promise<TokenData[]> {
        try {
            const tokenIds = await this.doResolveTokenEvents(addr, infamousCollectionName);
            const list: TokenData[] = [];
            for (const tokenId of tokenIds) {
                const tokenData = await this.tokenData(tokenId);
                tokenData && list.push(tokenData);
            }
            return list;
        } catch (e) {
            return [];
        }
    }

    async tokenIdsOwned(addr: string): Promise<ITokenId[]> {
        try {
            return await this.doResolveTokenEvents(addr, infamousCollectionName);
        } catch (e) {
            return [];
        }
    }

    async tokenData(tokenId: ITokenId): Promise<TokenData | undefined> {
        try {
            return await this.doGetTokenData(tokenId);
        } catch (e) {}
    }

    async weaponIdsOwned(addr: string): Promise<ITokenId[]> {
        try {
            return await this.doResolveTokenEvents(addr, weaponCollectionName);
        } catch (e) {
            return [];
        }
    }

    async weaponData(weaponTokenName: string): Promise<TokenData | undefined> {
        const managerAddress = await this.getManagerAddress();
        const tokenId: ITokenId = {
            property_version: "0",
            token_data_id: {
                collection: weaponCollectionName,
                creator: managerAddress,
                name: weaponTokenName,
            },
        };

        return await this.tokenData(tokenId);
    }

    async accessoryIdsOwned(addr: string): Promise<ITokenId[]> {
        try {
            return await this.doResolveTokenEvents(addr, accessoryCollectionName);
        } catch (e) {
            return [];
        }
    }

    async accessoryData(accessoryTokenName: string): Promise<TokenData | undefined> {
        const managerAddress = await this.getManagerAddress();
        const tokenId: ITokenId = {
            property_version: "0",
            token_data_id: {
                collection: accessoryCollectionName,
                creator: managerAddress,
                name: accessoryTokenName,
            },
        };

        return await this.tokenData(tokenId);
    }

    async tokenLocked(addr: string): Promise<ITokenId[]> {
        try {
            const lockes = await this.getTokenLocks(addr);
            return (lockes.data as ITokenLocks).locking;
        } catch (e) {
            return [];
        }
    }

    async tokenLockData(tokenId: ITokenId): Promise<ILockingTime | undefined> {
        const tokenLockData = await this.getTokenLockData();
        const data = tokenLockData.data as ITokenLocksData;
        const lockingTime = await this.tableItem(
            data.locking_time.handle,
            `0x3::token::TokenId`,
            `${this.deployment.moduleAddress}::${this.deployment.infamousLock}::LockingTime`,
            tokenId
        );
        return lockingTime as ILockingTime;
    }

    async tokenPerMinted(addr: string): Promise<number> {
        try {
            const stateResource = await this.getCollectionStatusInfo();
            const collectionStatusInfo = stateResource.data as ICollectionStatusInfo;
            return await this.tableItem(collectionStatusInfo.per_minted_table.handle, "address", "u64", addr);
        } catch (e) {
            return 0;
        }
    }

    async tokenMintTime(tokenId: ITokenId): Promise<string | undefined> {
        try {
            const stateResource = await this.getCollectionStatusInfo();
            const collectionStatusInfo = stateResource.data as ICollectionStatusInfo;
            return await this.tableItem(
                collectionStatusInfo.token_mint_time_table.handle,
                "0x3::token::TokenId",
                "u64",
                tokenId
            );
        } catch (e) {
            return undefined;
        }
    }

    async linkTotal(tokenId: ITokenId): Promise<LinkEvents | undefined> {
        try {
            const tokenLink = (await this.getTokenLink()).data as ILinkInfo;
            const events = (await this.tableItem(
                tokenLink.token_link_events_table.handle,
                "0x3::token::TokenId",
                `0x1::event::EventHandle<${this.deployment.moduleAddress}::${this.deployment.infamousLinkStatus}::LinkEvent>`,
                tokenId
            )) as LinkEvents;
            return events;
        } catch (e) {
            return undefined;
        }
    }

    async linkPage(events: LinkEvents, query?: PaginationArgs): Promise<LinkHistoryItem[]> {
        try {
            const linkEvents = await this.readClient.getEventsByCreationNumber(
                events.guid.id.addr,
                events.guid.id.creation_num,
                query
            );
            const list = linkEvents.map((e) => e.data as LinkHistoryItem);
            return list;
        } catch (e) {
            return [];
        }
    }

    private async getUpgradeInfo(): Promise<MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousUpgradeLevel}::UpgradeInfo`
        );
    }

    private async getOpenBoxStatus(): Promise<MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousBackendOpenBox}::OpenBoxStatus`
        );
    }
    private async getWeaponOpenBoxStatus(): Promise<MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousBackendTokenWeaponOpenBox}::OpenBoxStatus`
        );
    }

    private async getAccessoryOpenBoxStatus(): Promise<MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousBackendTokenAccessoryOpenBox}::OpenBoxStatus`
        );
    }

    private async getTokenLink(): Promise<MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousLinkStatus}::TokenLink`
        );
    }

    private async getTokenLocks(addr: string): Promise<MoveResource> {
        return await this.readClient.getAccountResource(
            addr,
            `${this.deployment.moduleAddress}::${this.deployment.infamousLock}::TokenLocks`
        );
    }
    private async getTokenLockData(): Promise<MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousLock}::TokenLocksData`
        );
    }

    private async doGetTokenData(tokenId: ITokenId): Promise<TokenData> {
        const collection: {type: string; data: any} = await this.readClient.getAccountResource(
            tokenId.token_data_id.creator,
            "0x3::token::Collections"
        );

        const {handle} = collection.data.token_data;
        const tokenData = (await this.tableItem(
            handle,
            "0x3::token::TokenDataId",
            "0x3::token::TokenData",
            tokenId.token_data_id
        )) as ITokenData;
        const properties: PropertyItem[] = [];
        tokenData.default_properties.map.data.forEach((p) => {
            properties.push({
                key: p.key,
                value: decodeValue(p.value.value, p.value.type),
            });
        });

        return {
            collection: tokenId.token_data_id.collection,
            description: tokenData.description,
            name: tokenData.name,
            maximum: tokenData.maximum,
            supply: tokenData.supply,
            uri: tokenData.uri,
            properties,
        };
    }

    private async doResolveTokenEvents(addr: string, collectionName: string): Promise<ITokenId[]> {
        const managerAddress = await this.getManagerAddress();
        const tokenStore = await this.getTokenStoreInfo(addr);

        const depositEvents = await this.getAllEvents(tokenStore.data.deposit_events, "0x3::token::DepositEvent");

        const withdrawEvents = await this.getAllEvents(tokenStore.data.withdraw_events, "0x3::token::WithdrawEvent");

        const events = [...withdrawEvents, ...depositEvents].filter(
            (e) =>
                e.tokenId.token_data_id.collection === collectionName &&
                e.tokenId.token_data_id.creator === managerAddress
        );
        events.sort((a, b) => {
            return parseInt(a.version) - parseInt(b.version);
        });

        const tokenIds: ITokenId[] = [];

        for (const event of events) {
            if (event.type === "0x3::token::DepositEvent") {
                tokenIds.push(event.tokenId);
            } else {
                const existIndex = tokenIds.findIndex(
                    (id) => id.token_data_id.name === event.tokenId.token_data_id.name
                );
                if (existIndex > -1) tokenIds.splice(existIndex, 1);
            }
        }

        return tokenIds;
    }

    private async getAllEvents(event: IEvent, eventType: TokenEventType) {
        const counter = parseInt(event.counter);

        if (counter) {
            const eventId = event.guid.id;
            const key = `${eventType}-${eventId.addr}-${eventId.creation_num}`;
            const cached = (await localCache.get(key)) as {count: number; allEvents: IEventItem[]};
            let start = 0;
            const cachedEvents = cached?.allEvents || [];
            if (cached) {
                if (cached.count === counter) {
                    return cached.allEvents;
                } else {
                    start = cached.count;
                }
            }
            const leftEvents = await this.getEvents(start, counter, eventId, eventType);
            const allEvents = [...cachedEvents, ...leftEvents];
            await localCache.set(key, {count: counter, allEvents});
            return allEvents;
        }
        return [];
    }

    private async getEvents(
        start: number,
        end: number,
        eventId: {
            addr: string;
            creation_num: string;
        },
        eventType: TokenEventType
    ) {
        const allEvants: IEventItem[] = [];
        const pageSize = 24;
        for (let index = start; start < end; start = start + pageSize) {
            const limit = Math.min(end - index, pageSize);
            const events = (await this.readClient.getEventsByCreationNumber(eventId.addr, eventId.creation_num, {
                start,
                limit,
            })) as TokenEvent[];
            events.forEach((e) => {
                allEvants.push({tokenId: e.data.id, type: eventType, version: e.version});
            });
        }
        return allEvants;
    }

    private async getCollectionStatusInfo(): Promise<MoveResource> {
        return await this.readClient.getAccountResource(
            this.deployment.moduleAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousNft}::CollectionInfo`
        );
    }

    private async getManagerAddress(): Promise<string> {
        if (this.manager_addr) {
            return this.manager_addr;
        }
        const managerAccountCapability = await this.getManagerAccountCapability();
        if (managerAccountCapability) {
            const info = managerAccountCapability.data as IManagerAccountCapability;
            this.manager_addr = info.signer_cap.account;
            return this.manager_addr;
        } else {
            throw new Error("ManagerAccountCapability not found");
        }
    }

    private async getTokenStoreInfo(addr: string): Promise<ITokenStore> {
        const tokenStore = await this.readClient.getAccountResource(addr, tokenStoreResource);
        return tokenStore as ITokenStore;
    }

    private async getManagerAccountCapability(): Promise<MoveResource> {
        return await this.readClient.getAccountResource(
            this.deployment.moduleAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousManagerCap}::ManagerAccountCapability`
        );
    }

    private async tableItem(handle: string, keyType: string, valueType: string, key: any): Promise<any> {
        const getTokenTableItemRequest = {
            key_type: keyType,
            value_type: valueType,
            key,
        };

        return this.readClient.getTableItem(handle, getTokenTableItemRequest);
    }
}

export function decodeValue(value: string, type: string): string {
    if (type === "u64") {
        return decodeU64(value).toString();
    }
    if (type === "0x1::string::String") {
        return decodeString(value);
    }
    return value;
}
