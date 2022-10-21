import localForage from "localforage";

const INFAMOUS_PREFIX = `infamous-data-`;
export class IndexedDbStorage {
    storage: LocalForage = localForage;
    constructor(dbName?: string, storeName?: string, description?: string) {
        this.storage = localForage.createInstance({
            name: dbName || "infamous",
            storeName: storeName || "infmousData",
            description: description || "infmous aptos cache data",
        });
    }

    async get(key: string): Promise<unknown> {
        const itemKey = `${INFAMOUS_PREFIX}${key}`;
        const storageData = await this.storage.getItem(itemKey);
        if (storageData) {
            return storageData;
        }
        return Promise.resolve(null);
    }

    async set(key: string, items: any): Promise<void> {
        if (items) {
            const itemKey = `${INFAMOUS_PREFIX}${key}`;
            try {
                await this.storage.setItem(itemKey, items);
            } catch (e) {
                throw new Error(`${key}:${JSON.stringify(items)} indexedDB storage set error`);
            }
        }
    }

    async remove(key: string): Promise<void> {
        const itemKey = `${INFAMOUS_PREFIX}${key}`;
        return await this.storage.removeItem(itemKey);
    }

    async clear(): Promise<void> {
        return await this.storage.clear();
    }
}

export const localCache = new IndexedDbStorage();
