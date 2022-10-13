export function stringToHex(text: string) {
    const encoder = new TextEncoder();
    const encoded = encoder.encode(text);
    return Array.from(encoded, (i) => i.toString(16).padStart(2, "0")).join("");
}

export function parseJson(text: string) {
    return JSON.parse(text);
}

export function paramToHex(value: string, type: string) {
    if (type === "address") {
        return value.startsWith("0x") ? value.substring(2) : value;
    } else if (type === "0x1::string::String") {
        return value;
    } else if (type === "u64") {
        return value;
    } else if (type === "vector<u8>") {
        return stringToHex(value);
    } else if (type === "vector<vector<u8>>") {
        const arr = parseJson(value);
        return arr.map((a: any) => stringToHex(a as string));
    } else if (type === "vector<bool>" || type === "vector<0x1::string::String>") {
        return parseJson(value);
    }
    return value;
}

export function decodeU64(u64String: string): number {
    if (!u64String) {
        return 0;
    }
    const str = u64String.startsWith("0x") ? u64String.slice(2).split("") : u64String.split("");
    const twoPad = str.reduce((acc: string[], cur: string, idx: number) => {
        if (idx % 2 === 0) {
            acc.push(cur);
        } else {
            const start = acc[acc.length - 1];
            acc[acc.length - 1] = `${start}${cur}`;
        }
        return acc;
    }, []);
    const u8 = new Uint8Array(twoPad.map((value) => parseInt(value, 16)));
    const reversed = u8.reverse();
    return reversed.reduce((acc: number, cur: number) => {
        acc = acc * 256 + cur;
        return acc;
    }, 0);
}

export function decodeString(u64String: string): string {
    if (!u64String) {
        return "";
    }
    const str = u64String.startsWith("0x") ? u64String.slice(2).split("") : u64String.split("");
    const twoPad = str.reduce((acc: string[], cur: string, idx: number) => {
        if (idx % 2 === 0) {
            acc.push(cur);
        } else {
            const start = acc[acc.length - 1];
            acc[acc.length - 1] = `${start}${cur}`;
        }
        return acc;
    }, []);
    const u8 = new Uint8Array(twoPad.map((value) => parseInt(value, 16)));
    const lenRemovedStr = u8.slice(1);
    return lenRemovedStr.reduce((acc: string, cur: number) => {
        acc = `${acc}${String.fromCharCode(cur)}`;
        return acc;
    }, "");
}
