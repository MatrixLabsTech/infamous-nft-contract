import {InfamousNFTClient, ITransaction} from "./InfamousNFTClient";

import * as Gen from "aptos/dist/generated";
import {tokenStoreResource, collectionName, collectionResource, deployment} from "./config/development";
import {IManagerAccountCapability} from "./ManagerAccountCapability";
import {CollectionInfo, Collections, DepositEvent, ITokenDataId, ITokenId, ITokenStore} from "./CollectionInfo";
import {paramToHex} from "./utils/param";
import {AptosClient, TokenClient} from "aptos";
import {DEVNET_REST_SERVICE, TESTNET_REST_SERVICE} from "./consts/networks";

export type Network = "testnet" | "devnet";
export interface IDeployment {
    moduleAddress: string;
    creator: string;
    moduleName: string;
    manager_cap: string;
    version: number;
}

export class InfamousNFTClientImpl implements InfamousNFTClient {
    readClient: AptosClient;
    deployment: IDeployment;
    tokenClient: TokenClient;
    constructor(network: Network = "devnet") {
        if (network === "testnet") {
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
            function: `${this.deployment.moduleAddress}::${this.deployment.moduleName}::mint`,
            arguments: [paramToHex(count, "u64")],
            type_arguments: [],
        };
    }

    /**
     *
     * @returns collection info
     */
    async collectionInfo(): Promise<CollectionInfo> {
        const managerAddress = await this.getManagerAddress();
        const collectionInfo = await this.tokenClient.getCollectionData(managerAddress, collectionName);

        return collectionInfo;
    }

    async tokenOwned(addr: string): Promise<ITokenDataId[]> {
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

        return tokenIds.map((tokenId) => tokenId.token_data_id);
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
            this.deployment.creator,
            `${this.deployment.moduleAddress}::${this.deployment.manager_cap}::ManagerAccountCapability`
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
