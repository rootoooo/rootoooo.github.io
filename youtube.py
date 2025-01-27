# 获取 YouTube 直播的真实流媒体地址
import requests
import re

class Youtube:
    def __init__(self, url):
        if url.startswith('http'):
            if 'watch?v=' in url:
                self.handle = 'live/' + url.split('=')[-1]
            else:
                parts = url.split('/')
                supported_live_type = ['live', 'user', 'c', 'channel']
                if len(parts) < 2 or parts[-2] not in supported_live_type:
                    raise RuntimeError('Invalid YouTube URL.')
                self.handle = parts[-2] + '/' + parts[-1]
        else:
            self.handle = 'live/' + url

    def get_real_url(self):
        youtube_url = f'https://www.youtube.com/{self.handle}/live'
        headers = {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36'
        }
        try:
            response = requests.get(url=youtube_url, headers=headers, timeout=30)
            if response.status_code == 200:
                urls = re.findall(r'"hlsManifestUrl":"(.*?\.m3u8)"', response.text)
                return urls if urls else None
            else:
                print(f"Failed to fetch URL ({youtube_url}), status code: {response.status_code}")
                return None
        except Exception as e:
            print(f"Error fetching URL ({youtube_url}): {e}")
            return None


if __name__ == '__main__':
    # 添加需要处理的 YouTube 直播地址列表
    youtube_urls = [
        "https://www.youtube.com/watch?v=HFib76ySpbU",  # 凤凰视频
        "https://www.youtube.com/watch?v=vr3XyVCR4T0"   # 中天新闻
    ]

    print("开始获取 YouTube 直播的真实流媒体地址：\n")
    for url in youtube_urls:
        print(f"直播地址: {url}")
        try:
            real_url = Youtube(url).get_real_url()
            if real_url:
                print("真实流地址：")
                for stream_url in real_url:
                    print(f"- {stream_url}")
            else:
                print("未开播或未找到真实流地址")
        except Exception as e:
            print(f"处理 {url} 时出错: {e}")
        print("\n")
