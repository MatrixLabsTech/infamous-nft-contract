import axios, {AxiosRequestConfig} from "axios";
export async function postData(url: string, data?: any, config?: AxiosRequestConfig<any> | undefined) {
    return await axios.post(url, data, config);
}
