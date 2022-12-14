/// This module provides the common configs of ndt collection and common tools to manage string/u64 things.
module infamous::infamous_common {

    use std::string::{Self, String};
    use std::vector;

    public fun infamous_collection_name(): String {
        string::utf8(b"InfamousNFT")
    }

    public fun infamous_collection_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/collection.png")
    }

    public fun infamous_base_token_name(): String {
        string::utf8(b"Infamous #")
    }

    
    public fun infamous_token_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/box.png")
    }

    public fun infamous_base_token_uri(): String {
        string::utf8(b"https://beta.pfp.infamousnft.xyz/origin/")
    }

    public fun infamous_description(): String {
        string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs.")
    }

    public fun infamous_weapon_collection_name(): String {
        string::utf8(b"InfamousWeaponNFT")
    }

    public fun infamous_weapon_collection_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/weapon-collection.png")
    }

    public fun infamous_weapon_base_token_name(): String {
        string::utf8(b"Infamous Weapon #")
    }
    
    public fun infamous_weapon_base_token_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/media/weapon/origin/")
    }

    public fun infamous_weapon_token_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/normal_armorybox.png")
    }

    public fun infamous_weapon_earlybird_token_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/earlybird_armorybox.png")
    }

    public fun infamous_weapon_description(): String {
        string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs")
    }



    public fun infamous_accessory_collection_name(): String {
        string::utf8(b"InfamousAccessoryNFT")
    }

    public fun infamous_accessory_collection_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/accessory-collection.png")
    }

    public fun infamous_accessory_base_token_name(): String {
        string::utf8(b"Infamous Accessory #")
    }
    
    public fun infamous_accessory_base_token_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/media/accessory/origin/")
    }

    public fun infamous_accessory_token_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/normal_accessorybox.png")
    }

    public fun infamous_accessory_earlybird_token_uri(): String {
        string::utf8(b"https://media.nft.infamousnft.xyz/static/earlybird_accessorybox.png")
    }


    public fun infamous_accessory_description(): String {
        string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs")
    }

    /// Helper to append number to string
    public fun append_num(base_str: String, num: u64): String {
        let str = copy base_str;
        string::append(&mut str, u64_string(num));
        str
    }

    /// helper to convert u64 to string
    public fun u64_string(value: u64): String{
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    /// helper to convert u128 to string
    public fun u128_to_string(value: u128): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    /// Helper to remove an element from a vector.
    public fun remove_element<E: drop>(v: &mut vector<E>, x: &E) {
        let (found, index) = vector::index_of(v, x);
        if (found) {
            vector::remove(v, index);
        }
    }

    /// Helper to add an element to a vector.
    public fun add_element<E: drop>(v: &mut vector<E>, x: E) {
        if (!vector::contains(v, &x)) {
            vector::push_back(v, x)
        }
    }

    /// escape the string, replace ` ` with `-`
    public fun escape_whitespace(value: String): String {
        let bytes = string::bytes(&value);
        let i = 0;
        let result = vector::empty<u8>();
        while (i < vector::length<u8>(bytes)) {
            let v = *vector::borrow<u8>(bytes, i);
            if(v == 32){
                vector::push_back(&mut result, 45);
            }else {
                vector::push_back(&mut result, v);
            };
            i = i + 1;
        };
        string::utf8(result)
    }

    #[test()]
    public fun escape_whitespace_test() {
        let before_str = string::utf8(b"sds sd");
        let after_str = string::utf8(b"sds-sd");
        let result = escape_whitespace(before_str);
        assert!(after_str == result, 1);

    }
  
}
