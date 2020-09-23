<div align="center">

## A ShellSort with a twist \- Revised and even faster\! \(7 March 2009\)

<img src="PIC200868053448548.jpg">
</div>

### Description

This shell algorithm is founded on a very solid performer that was originally developed by vb2themax, and optimized further by several very talented coders, before I twisted a little more out of it in this hybrid version.



----

This latest version employs a clever SAFEARRAY substitution technique to trick VB into thinking the four-byte string pointers in the string array are just VB longs in a native VB long array, and is now much faster.



----

Also uses valid addition and subtraction of unsigned long integers to guarantee safe arithmetic operations on memory address pointers.



----

Includes both Shell and ShellHyb algorithms with indexed versions in 25kb class and demo project.



----

Update 21 June 2008 inspired by comments from Roger Gilchrist. Improved indexed sorting support routine to better exploit fast re-sorting performance, and added much needed index sorting documentation.



----

Obscure Bug Fix 7 March 09. I documented they 'can sort sub-sets of the array data' but with the indexed versions if you do an error *could* occur without this very small change.
 
### More Info
 


<span>             |<span>
---                |---
**Submitted On**   |2008-04-02 11:40:08
**By**             |[Rde](https://github.com/Planet-Source-Code/PSCIndex/blob/master/ByAuthor/rde.md)
**Level**          |Intermediate
**User Rating**    |5.0 (100 globes from 20 users)
**Compatibility**  |VB 4\.0 \(32\-bit\), VB 5\.0, VB 6\.0
**Category**       |[Data Structures](https://github.com/Planet-Source-Code/PSCIndex/blob/master/ByCategory/data-structures__1-33.md)
**World**          |[Visual Basic](https://github.com/Planet-Source-Code/PSCIndex/blob/master/ByWorld/visual-basic.md)
**Archive File**   |[A\_ShellSor214611372009\.zip](https://github.com/Planet-Source-Code/rde-a-shellsort-with-a-twist-revised-and-even-faster-7-march-2009__1-70654/archive/master.zip)





### Source Code

<BLOCKQUOTE>
<FONT SIZE="+1">
<H2 ALIGN="center">Shell Hybrid</H2>
<br />
<P>
 This shell algorithm is founded on a very solid performer that was originally developed by vb2themax, and optimized further by several very talented coders, before I twisted a little more out of it in this hybrid version. This shellsort is unbelievably optimized and is a solid performer on all data with no known weaknesses.
</P>
<P>
 Although ShellHyb is optimized for re-sorting and reverse sorting, it also has been greatly boosted in raw outright speed to square up against anything, anytime!
</P>
<P>
 This is the fastest shellsort** I know of. This algorithm excels on both un-sorted and pre-sorted data.
</P>
</FONT>
 <CODE>**A hybrid shellsort with a twist, and no bubbles.</CODE>
<FONT SIZE="+1">
<P>
 Shell algorithms very smartly reduce large sized arrays down to many small semi-sorted chunks, but then spend most of their short working time reducing these chunks down to ordered pairs to finish like a bubblesort.
</P>
<P>
 As these chunks get smaller the code makes less and less actual changes, and the bubble finishing run therefore makes very few changes to the almost sorted array.
</P>
<P>
 This means a shell algorithm is very good at pre-sorting but falls behind the fastest quicksort in outright speed because of its dependance on a slow bubble finish.
</P>
<P>
 This hybrid shell addresses this issue by replacing the bubble with a built in algorithm that is optimized for pre-sorted data.
</P>
<H3 ALIGN="center">Revised Version</H3>
<P>
 The latest version of this algorithm employs a SAFEARRAY substitution
 technique to trick VB into thinking the four-byte string pointers in
 the string array are just VB longs in a native VB long array.
</P>
<P>
 The technique simply uses CopyMemory to point a VB long array (defined
 in the class) at the first of the string pointers in memory, and sets
 its lower-bound and item count to match (as if it had been redimmed).
</P>
<P>
 This allows us to treat the string pointers as if they were simply
 four-byte long values in a long array and can be swapped around as
 needed without touching the actual strings that are pointed to.
</P>
<P>
 Reading and assigning to a VB long array is lightning fast, and proves
 to be considerably faster when copying only one item than the previous
 method of copying the string pointers using CopyMemory.
</P>
<H3 ALIGN="center">Indexed Sort</H3>
<p>Included are indexed versions which receive a dynamic long array to hold
references to the string array indices which is known as an indexed sort.
No changes are made to the source string array.</p>
<p>After a sort procedure is run the long array is ready as a sorted
index (lookup table) to the string array items,
so <b><code> strA(idxA(lo)) </code></b> returns
the lo item in the string array whose index
may be anywhere in the string array.</p>
<p><b>Usage:</b> The index array can be redimmed to match the source string array
boundaries or it can be erased or left uninitialized before sorting
a string array for the first time. However, if you modify string items
and re-sort you <b>should not</b> redim or erase the index array to
take advantage of the fast refresh sorting performance. This also allows
the index array to be passed on to other sorting processes to be further manipulated.</p>
<p>Even when using redim with the preserve keyword and adding more items to
the string array you can pass the index array unchanged and the new items
will be sorted into the previously sorted array. The index array will automatically
return with boundaries matching the string array boundaries.</p>
<p>Only when you reload the string array items with new array boundaries should you
erase the index array for the first sorting operation. Also, if you redim the
source string array to smaller boundaries you should erase the index array before
sorting the new smaller data set for the first time.</p>
<H3 ALIGN="center">Unsigned Longs</H3>
<P>
 This new version also uses a function to enable valid addition and subtraction of unsigned long integers. This guarantees safe arithmetic operations on memory address pointers.
</P>
<H3 ALIGN="center">Features</H3>
<p>This algorithm has the following features:</p>
<P>
 - It can handle sorting arrays of millions of string items.<br />
 - It can handle sorting in ascending and descending order.<br />
 - It can handle case-sensitive and case-insensitive criteria.<br />
 - It can handle zero or higher based arrays.<br />
 - It can handle negative lb and positive ub.<br />
 - It can handle negative lb and zero or negative ub.<br />
 - It can sort sub-sets of the array data.
</P>
<P>
Happy coding :)
</P>
<P ALIGN="center">
...
</P>
</FONT>
</BLOCKQUOTE>

