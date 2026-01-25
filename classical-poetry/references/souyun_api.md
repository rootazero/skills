# Souyun Open API (excerpt)

Base URL: `https://api.sou-yun.cn/open`

## 1. Poem

Search poems by keyword, author, dynasty, title, sentence, rhyme.

- Endpoint: `/poem`
- Required: `key` (keyword or poem id)
- Optional: `dynasty`, `scope`, `type`, `rhyme`, `pageno`, `jsontype`

Examples:

```
https://api.sou-yun.cn/open/poem?key=7734&jsontype=true
https://api.sou-yun.cn/open/poem?key=王之涣&scope=Author&dynasty=Tang&jsontype=true
https://api.sou-yun.cn/open/poem?key=登鹳雀楼&scope=Title&dynasty=Tang&jsontype=true
https://api.sou-yun.cn/open/poem?key=白日依山尽&scope=Sentence&dynasty=Tang&jsontype=true
https://api.sou-yun.cn/open/poem?key=白&type=QiLv&rhyme=江&jsontype=true
```

## 2. RhymeCategory

Query 平水韵韵目 and characters.

- Endpoint: `/RhymeCategory`
- List: `/RhymeCategory/list`
- By category: `/RhymeCategory?id=东`

## 3. RhymeDictionary

Query a character for rhyme info, word/phrase examples, and sentence examples.

- Endpoint: `/rhymeDictionary`
- Required: `id` (single character)
- Optional: `qtype` (0-5), `pageNo`

Examples:

```
https://api.sou-yun.cn/open/rhymeDictionary?id=天
https://api.sou-yun.cn/open/rhymeDictionary?id=看&qtype=5&pageNo=2
```

## 4. CoupletWords

Query couplet word suggestions.

- Endpoint: `/coupletwords`
- Required: `id` (keyword or phrase)

Examples:

```
https://api.sou-yun.cn/open/coupletwords?id=有
https://api.sou-yun.cn/open/coupletwords?id=人间
https://api.sou-yun.cn/open/coupletwords?id=三千里
```
