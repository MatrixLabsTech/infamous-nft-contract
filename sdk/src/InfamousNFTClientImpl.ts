import {InfamousNFTClient, ITransaction} from "./InfamousNFTClient";

import * as Gen from "aptos/dist/generated";
import {tokenStoreResource, collectionName, deployment, IDeployment} from "./config/development";
import {IManagerAccountCapability} from "./ManagerAccountCapability";
import {CollectionInfo, DepositEvent, ICollectionStatusInfo, ITokenId, ITokenStore, TokenData} from "./CollectionInfo";
import {paramToHex} from "./utils/param";
import {AptosClient, TokenClient} from "aptos";
import {DEVNET_REST_SERVICE, TESTNET_REST_SERVICE} from "./consts/networks";
export enum AptosNetwork {
    Testnet = "Testnet",
    Mainnet = "Mainnet",
    Devnet = "Devnet",
}

export class InfamousNFTClientImpl implements InfamousNFTClient {
    readClient: AptosClient;
    deployment: IDeployment;
    tokenClient: TokenClient;
    constructor(network: AptosNetwork = AptosNetwork.Devnet) {
        if (network === AptosNetwork.Testnet) {
            this.readClient = new AptosClient(TESTNET_REST_SERVICE);
            this.deployment = deployment.testnet;
            this.tokenClient = new TokenClient(this.readClient);
        } else {
            this.readClient = new AptosClient(DEVNET_REST_SERVICE);
            this.deployment = deployment.devnet;
            this.tokenClient = new TokenClient(this.readClient);
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

    stakeTransaction(tokenName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousStake}::stake_infamous_nft_script`,
            arguments: [paramToHex(tokenName, "0x1::string::String")],
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

    async collectionInfo(): Promise<CollectionInfo> {
        const managerAddress = await this.getManagerAddress();
        const collectionInfo = await this.tokenClient.getCollectionData(managerAddress, collectionName);
        return collectionInfo;
    }

    async tokenOwned(addr: string): Promise<TokenData[]> {
        try {
            const tokenIds = await this.doResolveTokenOwned(addr);
            const list: TokenData[] = [];
            for (const tokenId of tokenIds) {
                const tokenData = await this.tokenClient.getTokenData(
                    tokenId.token_data_id.creator,
                    tokenId.token_data_id.collection,
                    tokenId.token_data_id.name
                );
                list.push(tokenData);
            }
            return list;
        } catch (e) {
            return [];
        }
    }

    async tokenIdsOwned(addr: string): Promise<ITokenId[]> {
        try {
            return await this.doResolveTokenOwned(addr);
        } catch (e) {
            return [];
        }
    }

    async tokenData(tokenId: ITokenId): Promise<TokenData | undefined> {
        try {
            return await this.doGetTokenData(tokenId);
        } catch (e) {}
    }

    async tokenStaked(addr: string): Promise<ITokenId[]> {
        try {
            const stakes = await this.getTokenStakes(addr);
            return stakes.data as ITokenId[];
        } catch (e) {
            return [];
        }
    }

    async tokenStakeData(tokenId: ITokenId): Promise<TokenData | undefined> {
        throw new Error("Method not implemented.");
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

    private async doGetTokenData(tokenId: ITokenId): Promise<TokenData> {
        const tokenData = await this.tokenClient.getTokenData(
            tokenId.token_data_id.creator,
            tokenId.token_data_id.collection,
            tokenId.token_data_id.name
        );
        return tokenData;
    }

    private async doResolveTokenOwned(addr: string): Promise<ITokenId[]> {
        const managerAddress = await this.getManagerAddress();
        const tokenStore = await this.getTokenStoreInfo(addr);

        let tokenIds: ITokenId[] = [];
        const depositEvents = (await this.readClient.getEventsByCreationNumber(
            tokenStore.data.deposit_events.guid.id.addr,
            tokenStore.data.deposit_events.guid.id.creation_num
        )) as DepositEvent[];
        depositEvents.forEach((e) => {
            if (
                e.data.id.token_data_id.collection === collectionName &&
                e.data.id.token_data_id.creator === managerAddress
            ) {
                tokenIds.push(e.data.id);
            }
        });

        const burnEvents = await this.readClient.getEventsByCreationNumber(
            tokenStore.data.burn_events.guid.id.addr,
            tokenStore.data.burn_events.guid.id.creation_num
        );

        burnEvents.forEach((e) => {
            if (
                e.data.id.token_data_id.collection === collectionName &&
                e.data.id.token_data_id.creator === managerAddress
            ) {
                tokenIds = tokenIds.filter((id) => {
                    return !(
                        id.property_version === e.data.id.property_version &&
                        id.token_data_id.creator === e.data.id.token_data_id.creator &&
                        id.token_data_id.name === e.data.id.token_data_id.name
                    );
                });
            }
        });

        const withdrawEvents = await this.readClient.getEventsByCreationNumber(
            tokenStore.data.withdraw_events.guid.id.addr,
            tokenStore.data.withdraw_events.guid.id.creation_num
        );

        withdrawEvents.forEach((e) => {
            if (
                e.data.id.token_data_id.collection === collectionName &&
                e.data.id.token_data_id.creator === managerAddress
            ) {
                const existIndex = tokenIds.findIndex(
                    (id) =>
                        id.property_version === e.data.id.property_version &&
                        id.token_data_id.creator === e.data.id.token_data_id.creator &&
                        id.token_data_id.name === e.data.id.token_data_id.name
                );
                if (existIndex > -1) tokenIds = tokenIds.filter((_, index) => index !== existIndex);
            }
        });
        return tokenIds;
    }

    private async getCollectionStatusInfo(): Promise<Gen.MoveResource> {
        return await this.readClient.getAccountResource(
            this.deployment.moduleAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousNft}::CollectionInfo`
        );
    }

    private async getManagerAddress(): Promise<string> {
        const managerAccountCapability = await this.getManagerAccountCapability();
        if (managerAccountCapability) {
            const info = managerAccountCapability.data as IManagerAccountCapability;
            return info.signer_cap.account;
        } else {
            throw new Error("ManagerAccountCapability not found");
        }
    }

    private async getTokenStoreInfo(addr: string): Promise<ITokenStore> {
        const tokenStore = await this.readClient.getAccountResource(addr, tokenStoreResource);
        return tokenStore as ITokenStore;
    }

    private async getManagerAccountCapability(): Promise<Gen.MoveResource> {
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
