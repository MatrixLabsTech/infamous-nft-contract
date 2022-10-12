module infamous::infamous_common {

    use std::string::{Self, String};
    use std::vector;
    use std::bcs;
    use std::debug;
    use aptos_std::from_bcs;
    use std::hash;


    public fun infamous_collection_name(): String {
        string::utf8(b"InfamousNFT")
    }

    public fun infamous_collection_uri(): String {
        string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/infamous_collection_name.png")
    }

    public fun infamous_base_token_name(): String {
        string::utf8(b"Infamous #")
    }

    
    public fun infamous_token_uri(): String {
        string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/box.png")
    }

    public fun infamous_base_token_uri(): String {
        string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/")
    }

    public fun infamous_description(): String {
        string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs")
    }

    public fun infamous_level_key(): String {
        string::utf8(b"level")
    }

    public fun infamous_weapon_key(): String {
        string::utf8(b"weapon")
    }

    public fun infamous_weapon_token_name_key(): String {
        string::utf8(b"weapon_token_name")
    }

    public fun infamous_weapon_collection_name(): String {
        string::utf8(b"InfamousWeaponNFT")
    }

    public fun infamous_weapon_collection_uri(): String {
        string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/infamous_collection_name.png")
    }

    public fun infamous_weapon_base_token_name(): String {
        string::utf8(b"NFMS #")
    }

    
    public fun infamous_weapon_base_token_uri(): String {
        string::utf8(b"https://beta.api.infamousnft.xyz/infamousnft/token/")
    }

    public fun infamous_weapon_description(): String {
        string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs")
    }

    /// Helper to append number to string
    public fun append_num(base_str: String, num: u64): String {
        let str = copy base_str;
        string::append(&mut str, u64_string(num));
        str
    }


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

    public fun add_element<E: drop>(v: &mut vector<E>, x: E) {
        if (!vector::contains(v, &x)) {
            vector::push_back(v, x)
        }
    }

    fun address_string(input: address): string::String {
        let bytes = bcs::to_bytes<address>(&input);
        let i = 0;
        let result = vector::empty<u8>();
        while (i < vector::length<u8>(&bytes)) {
        vector::append(&mut result, u8_hex_string_u8(*vector::borrow<u8>(&bytes, i)));
        i = i + 1;
        };
        string::utf8(result)
    }

    fun u8_hex_string_u8(input: u8): vector<u8> {
        let result = vector::empty<u8>();
        vector::push_back(&mut result, u4_hex_string_u8(input / 16));
        vector::push_back(&mut result, u4_hex_string_u8(input % 16));
        //string::utf8(result)
        result
    }

    fun u4_hex_string_u8(input: u8): u8 {
        if (input<=9) (48 + input) // 0 - 9 => ASCII 48 to 57
        else (55 + input) //10 - 15 => ASCII 65 to 70
    }

    public fun string_hash_string(value: String): String {
        let bytes = bcs::to_bytes<String>(&value);
        vector::remove(&mut bytes, 0); // has a 67 before,,,? dont known why
        let hashed = hash::sha3_256(bytes);
        debug::print<vector<u8>>(&hashed);
        address_string(from_bcs::to_address(hashed))
    }


    #[test()]
    public fun hash_test() {
        let before_str = string::utf8(b"Blue-dungaress-hoop earings-eyes closed-Straight eyebrows-band-aid-");
        let hashed_string = string_hash_string(before_str);
        debug::print<String>(&hashed_string);
    }
  
}
