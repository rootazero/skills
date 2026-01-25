import json
from urllib.parse import urlencode
from urllib.request import urlopen

BASE_URL = "https://api.sou-yun.cn/open"


def _get_json(path, params=None):
    url = f"{BASE_URL}/{path}"
    if params:
        url = f"{url}?{urlencode(params)}"
    with urlopen(url) as resp:
        payload = resp.read().decode("utf-8")
    return json.loads(payload)


def poem(
    key, dynasty=None, scope=None, poem_type=None, rhyme=None, page=None, json_type=True
):
    params = {"key": key, "jsontype": "true" if json_type else "false"}
    if dynasty is not None:
        params["dynasty"] = dynasty
    if scope is not None:
        params["scope"] = scope
    if poem_type is not None:
        params["type"] = poem_type
    if rhyme is not None:
        params["rhyme"] = rhyme
    if page is not None:
        params["pageno"] = page
    return _get_json("poem", params)


def rhyme_category_list():
    return _get_json("RhymeCategory/list")


def rhyme_category(category):
    return _get_json("RhymeCategory", {"id": category})


def rhyme_dictionary(char, qtype=None, page_no=None):
    params = {"id": char}
    if qtype is not None:
        params["qtype"] = qtype
    if page_no is not None:
        params["pageNo"] = page_no
    return _get_json("rhymeDictionary", params)


def couplet_words(word):
    return _get_json("coupletwords", {"id": word})
