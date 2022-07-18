#!/usr/bin/env ipython3

import pathlib
from functools import partial
from html.entities import name2codepoint
from html.parser import HTMLParser
from itertools import zip_longest
from re import IGNORECASE, compile

import scrapy


class RequirementsParser(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self)
        self.reqs = []

    def handle_data(self, data):
        if data not in ("\xa0", " "):
            self.reqs.append(data.removeprefix("\xa0"))


class QuotesSpider(scrapy.Spider):
    name = "cnm_catalog"
    urlstoyear = {
        "https://catalog.cnm.edu/content.php?catoid=48&navoid=7364": "2122",
        "https://catalog.cnm.edu/content.php?catoid=46&navoid=6447": "2021",
        "https://catalog.cnm.edu/content.php?catoid=44&navoid=5847": "1920",
        "https://catalog.cnm.edu/content.php?catoid=41&navoid=5195": "1819",  # noqa: E261 1820, for chronology make 1819
        "https://catalog.cnm.edu/content.php?catoid=27&navoid=2865": "1618",
    }

    start_urls = list(urlstoyear.keys())

    def parse(self, response, urlstoyear=urlstoyear):
        filename = pathlib.Path("programs_and_requirements.txt")
        if not pathlib.Path(filename).is_file():
            with open(filename, "w") as fn:
                fn.write("program|requirements|year\n")
        callbackfunc = partial(
            self.parsetwo, filename=filename, year=urlstoyear[response.url]
        )
        for link in response.css("td.block_content_outer").xpath(
            '//li/a[contains(@href, "preview_program")]'
        ):  # process list of program links on programs page of catalog
            nextpage = response.urljoin(link.attrib["href"])
            yield scrapy.Request(nextpage, callback=callbackfunc)

    def parsetwo(self, response, filename, year):
        # 1618 has different code for requirements. Also need to account for OR
        # and AND in requirements
        parser = RequirementsParser()
        raw_program = response.css("title")
        cleaned_program = (
            raw_program.get()[7:]
            .split(" - Central")[0]
            .strip()
            .replace(",", " ")  # noqa: E261
        )
        divclass = response.xpath('//div[@class="acalog-core"]')
        r = compile(r"(programproficiencies)|(programrequirements)", flags=IGNORECASE)  # noqa E501
        while divclass:
            if divclass[0].re(r):
                break
            divclass.pop(0)
        if len(divclass):
            raw_reqs = divclass[0].xpath('ul')
            reqs_strng = raw_reqs.get() if len(raw_reqs) else ""
            parser.feed(reqs_strng)
            towrite = repr(parser.reqs)
        else:
            towrite = ""
        with open(filename, "a") as fn:
            fn.write("|".join([cleaned_program, towrite, "".join([year, "\n"])]))  # noqa E501
