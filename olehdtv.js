const cheerio = createCheerio()
const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
const headers = {
  'Referer': 'https://www.olehdtv.com/',
  'Origin': 'https://www.olehdtv.com',
  'User-Agent': UA,
}

const appConfig = {
  ver: 1,
  title: "欧乐影院",
  site: "https://www.olehdtv.com",
  tabs: [{
    name: '首页',
    ext: {
      url: '/index.php',
      hasMore: false
    },
  }, {
    name: '电影',
    ext: {
      url: '/index.php/vod/show/id/1.html'
    },
  }, {
    name: '电视剧',
    ext: {
      url: '/index.php/vod/show/id/2.html',
    },
  }, {
    name: '综艺',
    ext: {
      url: '/index.php/vod/show/id/3.html',
    },
  }, {
    name: '动漫',
    ext: {
      url: '/index.php/vod/show/id/4.html'
    },
  }]
}

// API: 获取配置
async function getConfig() {
  return new Response(JSON.stringify(appConfig), {
    headers: { 'Content-Type': 'application/json' },
  })
}

// API: 获取影片卡片列表
async function getCards(ext) {
  ext = argsify(ext)
  let cards = []
  let url = ext.url
  let page = ext.page || 1
  let hasMore = ext.hasMore || true

  if (!hasMore && page > 1) {
    return new Response(JSON.stringify({ list: cards }), { headers: { 'Content-Type': 'application/json' } })
  }

  if (page > 1) {
    url = appConfig.site + url.replace('.html', `/page/${page}.html`)
  } else {
    url = appConfig.site + url
  }

  const { data } = await $fetch.get(url, { headers })

  const $ = cheerio.load(data)
  $('.vodlist_item > a').each((_, each) => {
    const path = $(each).attr('href')
    cards.push({
      vod_id: path,
      vod_name: $(each).attr('title'),
      vod_pic: $(each).attr('data-original'),
      vod_remarks: $(each).find('span.text_right > em.voddate').text(),
      ext: {
        url: appConfig.site + path,
      },
    })
  })

  return new Response(JSON.stringify({ list: cards }), { headers: { 'Content-Type': 'application/json' } })
}

// API: 获取影片播放链接
async function getTracks(ext) {
  const { url } = argsify(ext)
  let groups = []

  const { data } = await $fetch.get(url, { headers })

  const $ = cheerio.load(data)
  let group = { title: '在线', tracks: [] }
  $('.content_playlist.list_scroll > li > a').each((_, each) => {
    group.tracks.push({
      name: $(each).text(),
      pan: '',
      ext: {
        url: appConfig.site + $(each).attr('href')
      }
    })
  })

  if (group.tracks.length > 0) {
    groups.push(group)
  }

  return new Response(JSON.stringify({ list: groups }), { headers: { 'Content-Type': 'application/json' } })
}

// API: 获取影片播放信息（链接）
async function getPlayinfo(ext) {
  const { url } = argsify(ext)
  const { data } = await $fetch.get(url, { headers })
  const obj = JSON.parse(data.match(/player_aaaa=(.+?)<\/script>/)[1])
  const m3u = obj.url 
  return new Response(JSON.stringify({ urls: [m3u] }), { headers: { 'Content-Type': 'application/json' } })
}

// API: 搜索影片
async function search(ext) {
  ext = argsify(ext)
  let cards = []

  let text = encodeURIComponent(ext.text)
  let page = ext.page || 1
  if (page > 1) {
    return new Response(JSON.stringify({ list: cards }), { headers: { 'Content-Type': 'application/json' } })
  }

  const url = appConfig.site + `/index.php/vod/search.html?wd=${text}&submit=`
  const { data } = await $fetch.get(url, { headers })
  
  const $ = cheerio.load(data)
  $('a.vodlist_thumb').each((_, each) => {
    const path = $(each).attr('href')
    cards.push({
      vod_id: path,
      vod_name: $(each).attr('title'),
      vod_pic: $(each).attr('data-original'),
      vod_remarks: $(each).find('span.text_right').text(),
      ext: {
        url: appConfig.site + path,
      },
    })
  })

  return new Response(JSON.stringify({ list: cards }), { headers: { 'Content-Type': 'application/json' } })
}

// 将参数字典转为URL查询字符串
function dictToURI(dict) {
  var str = []
  for (var p in dict) {
    str.push(encodeURIComponent(p) + "=" + encodeURIComponent(dict[p]))
  }
  return str.join("&")
}

// 路由处理（可根据具体需求进行调整）
addEventListener('fetch', event => {
  const url = new URL(event.request.url)
  if (url.pathname === '/api/config') {
    event.respondWith(getConfig())
  } else if (url.pathname === '/api/cards') {
    event.respondWith(getCards({ url: '/index.php/vod/show/id/1.html', page: 1 }))
  } else if (url.pathname === '/api/tracks') {
    event.respondWith(getTracks({ url: '/index.php/vod/detail/id/1.html' }))
  } else if (url.pathname === '/api/playinfo') {
    event.respondWith(getPlayinfo({ url: '/index.php/vod/play/id/1.html' }))
  } else if (url.pathname === '/api/search') {
    const searchParams = new URLSearchParams(url.search)
    event.respondWith(search({ text: searchParams.get('wd'), page: 1 }))
  } else {
    event.respondWith(new Response('Not Found', { status: 404 }))
  }
})
