+++
date = "2013-02-02T11:28:43+02:00"
title = "Optimizing the operation of downloading files in Transifex"

+++

This is the story of taking a 80 seconds operation down to 2 seconds.

One of the most common operations in Transifex is downloading a
translation file (the second is uploading one). Since files are downloaded all the time, the process should be as fast as possible.

Some projects, however, have files with thousands of entries, which
presented us with some challenges: download times could take a lot of seconds depending on the size of the file — an issue for both our users and our servers :).

So, about a year back we had to take a good look at the process.

#### Exporting a file ####

The process of exporting a file is straightforward.

First, we fetch the *source strings* (the strings of the source language),  the *template file* of the resource and the corresponding *translation strings* in the specified language. If an entry has not been translated yet, we use the empty string as the translation.

The template file is almost the same with the source file (e.g. the
original PO file) of the resource, except that all translation strings have been replaced with a md5 hash that uniquely identifies the source string.

So, given the md5 hash, we can tell which source string the entry in
the template is for and which is the corresponding translation
string.

More details on the internals of the storage engine can be found in
the
[documentation](http://help.transifex.com/features/formats.html#the-transifex-translation-storage-engine) of Transifex.

#### Original algorithm ####

The algorithm (*compilation process*) would iterate over all
translation strings and use a regular expression to locate the hash
that corresponded to that string in the template file. Then, it would replace it with the actual translation string. The result was the translation file the user requested:

    source_strings = fetch_source_strings_from_db()
    translations = fetch_translations_from_db()
    for string in source_strings:
        translation = get_translation_for_source(translations, string)
        regex_replace(string.hash, translation, template)
    return template

#### Improvements ####

The first thing to do was to create a large PO file that could be used
as a reference point for measuring the impact of each improvement. The one we generated had some tens of thousands of `msgid` entries and the original algorithm needed about 80 seconds to *compile* the result.

#### Why regular expressions? ####

What struck us as odd was the use of regular expressions for what
should be a simple search-&amp;-replace operation. Regular expressions are known to be much slower than an equivalent simple text operation.

So, the first try was to change the regular expression call with a call to the replace function for strings. In Python, this means using
[`str.replace`](http://docs.python.org/library/stdtypes.html#str.replace)
instead of [`re.sub`](http://docs.python.org/library/re.html#re.sub).
The result was that the execution time dropped to half, to about 40s. But still, that was not enough.

#### Revisiting the compilation process ####

Going back to the compilation process, the main problem was the for
loop that iterated over all strings and did a search-and-replace in
the whole text **every** time. That means that the original template was
scanned multiple times — an `O(n^2)` algorithm. How could we do all replacements in one pass?

Regular expressions to the rescue! It turns out the `re.sub` function
can accept a function as an argument, which, given the matched object, returns a string to use as a replacement.

From then on the way to go was clear: we created a dictionary (hash or map in other languages), `translations`, that mapped each hash to the
corresponding string and a function, which, given a matched object,
would use the dictionary to return the correct string.

Then, all we needed to do is to construct a regular expression that
matches md5 hashes and use that and the above function as arguments in `re.sub` to replace all hashes with the corresponding strings in one pass of the template:

    md5_pattern = r'[0-9a-f]{32}'
    regex = re.compile(md5_pattern, re.IGNORECASE)
    return regex.sub(
            lambda m: translations.get(m.group(0), m.group(0)), text
        )

which is a `O(n)` algorithm.

The execution time was crashed to about 10 seconds (compared to the 80 seconds that were needed for the initial process). But still, not good
enough.

#### Dealing with PO files ####

The specific file we used for testing was a PO file and, given that
the gettext format (the format of PO files) is among the most popular
internationalization formats, we had to do better.

This time the main bottleneck was some extra processing of the PO file
performed at the end that adds the copyrights to the file header for
translators that contributed to the translation.

The previous implementation was iterating over the lines looking for
the appropriate place to insert the names of the translators. As soon
as it found that, it would insert them and then keep on iterating over
those lines. Adding an explicit `break` statement resulted in another
great decrease of the execution time: it dropped to **1-2 seconds**.

#### Conclusions ####

First, developers are pretty bad at finding the bottleneck of a process. The initial thought of the database queries being the bottleneck was totally wrong.

The most important thing, though, is that the most important thing to take care of are the algorithms we use in our work.
