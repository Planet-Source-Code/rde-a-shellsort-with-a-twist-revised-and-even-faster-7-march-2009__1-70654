VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cStrShell"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' cStrShell - Optimized ShellSort Algorithms         -©Rd-

' You are free to use any part or all of this code even for commercial
' purposes in any way you wish under the one condition that no copyright
' notice is moved or removed from where it is.

' These sorting routines have the following features:

' - They can handle sorting arrays of millions of string items.
' - They can handle sorting in ascending and descending order.
' - They can handle case-sensitive and case-insensitive criteria.
' - They can handle zero or higher based arrays.
' - They can handle negative lb and positive ub.
' - They can handle negative lb and zero or negative ub.
' - They can sort sub-sets of the array data.

' For comments, suggestions or bug reports you can contact me at:
' rd•edwards•bigpond•com.

' Declare some CopyMemory Alias's (thanks Bruce :)
Private Declare Sub CopyMemByV Lib "kernel32" Alias "RtlMoveMemory" (ByVal lpDest As Long, ByVal lpSrc As Long, ByVal lByteLen As Long)
Private Declare Sub CopyMemByR Lib "kernel32" Alias "RtlMoveMemory" (pDest As Any, pSrc As Any, ByVal lByteLen As Long)

' SAFEARRAY Header, used in place of the real one to trick VB into letting us access string data in-place
Private Type SAFEARRAY
    cDims      As Integer      ' Count of dimensions in this array
    fFeatures  As Integer      ' Bitfield flags indicating attributes of the array
    cbElements As Long         ' Byte size of each element of the array
    cLocks     As Long         ' Number of times the array has been locked without corresponding unlock. The cLocks field is a reference count that indicates how many times the array has been locked. When there is no lock, you're not supposed to access the array data, which is located in pvData.
    pvData     As Long         ' Pointer to the start of the array data (use only if cLocks > 0)
    cElements  As Long         ' Count of elements in this dimension
    lLbound    As Long         ' The lower-bounding index of this dimension
    lUbound    As Long         ' The upper-bounding index of this dimension
End Type

Private StrPointers_Header As SAFEARRAY
Private StrPointers() As Long

Private Const VT_BYREF = &H4000&         ' Tests whether the InitedArray routine was passed a Variant that contains an array, rather than directly an array in the former case ptr already points to the SA structure. Thanks to Monte Hansen for this fix
Private Const FADF_AUTO = &H1            ' Array is allocated on the stack
Private Const FADF_FIXEDSIZE = &H10      ' Array may not be resized or reallocated
Private Const FADF_NO_REDIM = FADF_AUTO Or FADF_FIXEDSIZE

' Used for unsigned arithmetic
Private Const DW_MSB = &H80000000 ' DWord Most Significant Bit

' More efficient repeated use of numeric literals
Private Const n0 = 0&, n1 = 1&, n2 = 2&, n3 = 3&, n4 = 4&, n8 = 8&, n12 = 12&, n16 = 16&

Public Enum eSortOrder
    Descending = &HFFFFFFFF ' -1
    Ascending = &H1&
    #If False Then
        Dim Descending, Ascending
    #End If
End Enum

Public Enum eCompareMethod
    BinaryCompare = &H0
    TextCompare = &H1
    #If False Then
        Dim BinaryCompare, TextCompare
    #End If
End Enum

Private Const Default_Order As Long = Ascending
Private Const Default_Method As Long = BinaryCompare

Private mMethod As eCompareMethod
Private mOrder As eSortOrder

Property Get SortMethod() As eCompareMethod
    SortMethod = mMethod
End Property

Property Let SortMethod(ByVal eNewMethod As eCompareMethod)
    mMethod = eNewMethod
End Property

Property Get SortOrder() As eSortOrder
    If mOrder = n0 Then mOrder = Default_Order
    SortOrder = mOrder
End Property

Property Let SortOrder(ByVal eNewOrder As eSortOrder)
    If eNewOrder = n0 Then
        If mOrder = n0 Then mOrder = Default_Order
    Else
        mOrder = eNewOrder
    End If
End Property

Private Sub Class_Initialize()
    mOrder = Default_Order
    mMethod = Default_Method
    With StrPointers_Header
        .cDims = n1                ' 1 Dimensional
        .fFeatures = FADF_NO_REDIM ' Cannot REDIM the array
        .cbElements = n4           ' This is a long array
        .cLocks = n1               ' Lock the array
    End With
    CopyMemByR ByVal ArrayPtr(StrPointers), VarPtr(StrPointers_Header), n4
End Sub

Private Sub Class_Terminate()
    CopyMemByR ByVal ArrayPtr(StrPointers), 0&, n4
End Sub

' + ShellSort +++++++++++++++++++++++++++++++++++++++++++

' This subroutine was developed directly from code by LukeH.
' Luke's shellsort algorithm is by far the fastest around, a
' tribute to his coding skills. Code origins: vb2themax :)

' This algorithm is unbelievably optimized and is a solid
' performer on all data with no known weaknesses.

Sub strShell(sA() As String, ByVal lbA As Long, ByVal ubA As Long)
   ' Thanks heaps to LukeH for this great algorithm :)
   If Not InitedArray(sA, lbA, ubA) Then Exit Sub
   Dim i As Long, j As Long, k As Long, l As Long
   Dim sItem As String, lpStr As Long, lItem As Long
   Dim eComp As eSortOrder
   With StrPointers_Header
      .pvData = VarPtr(sA(lbA))
      .cElements = ubA - lbA + n1
      .lLbound = lbA
   End With
   eComp = SortOrder                                          ' Initialize compare variable
   lpStr = VarPtr(sItem)                                      ' Cache the pointer to the string variable
   k = ubA - lbA      ' -----===========================----- ' Get the distance from lowerbound to upperbound
   Do: j = j + j + j + n1: Loop Until j > k                   ' Find the initial value for distance
   Do: j = j \ n3                                             ' Reduce distance by two thirds
      For i = lbA + j To ubA                                  ' Loop through each position in our current section
         lItem = StrPointers(i)                               ' Store the string pointer
         CopyMemByR ByVal lpStr, lItem, n4                    ' Put the current value in the buffer sItem (using its pointer)
         l = i - j                                            ' Set the pointer to the value below
         If StrComp(sA(l), sItem, mMethod) = eComp Then       ' Compare the current value with the immediately previous value
            k = i                                             ' If the wrong order then set our temp pointer to the current index
            Do: StrPointers(k) = StrPointers(l)               ' Copy the lower value to the current value
               k = l: l = l - j '-vb2themax-                  ' Adjust the pointers to compare down a level
               If l < lbA Then Exit Do                        ' Make sure we're in-bounds or exit the loop
            Loop While StrComp(sA(l), sItem, mMethod) = eComp ' Keep going as long as current value needs to move down
            StrPointers(k) = lItem                            ' Put the buffered value back in the correct position
      End If: Next                                            ' Increment the inner for loop
   Loop Until j < n1  ' -----===========================----- ' Drop out when we're done
   CopyMemByR ByVal lpStr, 0&, n4                             ' De-reference our pointer to sItem variable
End Sub

' + Shell Sort Indexed +++++++++++++++++++++++++++++++++++

' This is an indexed implementation of the above shell algorithm.

' This version uses a long array that holds references to the string
' arrays indices. This is known as an indexed sort. No changes are made
' to the source string array.

' After a sort procedure is run the long array is ready as a sorted
' index (lookup table) to the string array items.

' E.G sA(idxA(lo)) returns the lo item in the string array whose
' index may be anywhere in the string array.

Sub strShellIndexed(sA() As String, idxA() As Long, ByVal lbA As Long, ByVal ubA As Long)
   ' Thanks heaps to LukeH for this great algorithm :)
   If Not InitedArray(sA, lbA, ubA) Then Exit Sub
   Dim i As Long, j As Long, k As Long, l As Long
   Dim s As String, lpStr As Long, lp As Long
   Dim eComp As eSortOrder, idx As Long
   ValidateIndexArray idxA, lbA, ubA                            ' Validate the index array
   lp = Sum(VarPtr(sA(lbA)), -(lbA * n4))                       ' Cache the pointer to the array
   eComp = SortOrder                                            ' Initialize compare variable
   lpStr = VarPtr(s)                                            ' Cache the pointer to the string variable
   k = ubA - lbA      ' -----=============================----- ' Get the distance from lowerbound to upperbound
   Do: j = j + j + j + n1: Loop Until j > k                     ' Find the initial value for distance
   Do: j = j \ n3                                               ' Reduce distance by two thirds
      For i = lbA + j To ubA                                    ' Loop through each position in our current section
         CopyMemByV lpStr, Sum(lp, idxA(i) * n4), n4            ' Put the current value in the string buffer (using its pointer)
         idx = idxA(i)                                          ' Put the current index in the index buffer
         l = i - j                                              ' Set the pointer to the value below
         If StrComp(sA(idxA(l)), s, mMethod) = eComp Then       ' Compare the current value with the immediately previous value
            k = i                                               ' If the wrong order then set our temp pointer to the current index
            Do: idxA(k) = idxA(l)                               ' Copy the lower index to the current index
               k = l: l = l - j '-vb2themax-                    ' Adjust the pointers to compare down a level
               If l < lbA Then Exit Do                          ' Make sure we're in-bounds or exit the loop
            Loop While StrComp(sA(idxA(l)), s, mMethod) = eComp ' Keep going as long as current value needs to move down
            idxA(k) = idx                                       ' Put the buffered index back in the correct position
      End If: Next                                              ' Increment the inner for loop
   Loop Until j < n1  ' -----=============================----- ' Drop out when we're done
   CopyMemByR ByVal lpStr, 0&, n4                               ' De-reference our pointer to variable s
End Sub

' + Shell Hybrid ++++++++++++++++++++++++++++++++++++++

' This shell algorithm is founded on a very solid performer
' that was originally developed by vb2themax, and optimized
' further by several very talented coders, before I twisted
' a little more out of it in this hybrid version.

' This is the fastest shellsort I know of by far*. This
' algorithm excels on both un-sorted and pre-sorted data.

' *A hybrid shellsort with a twist, and no bubbles.

' Shell algorithms very smartly reduce large sized arrays
' down to many small semi-sorted chunks, but then spend most
' of their short working time reducing these chunks down to
' ordered pairs to finish like a bubblesort.

' As these chunks get smaller the code makes less and less
' actual changes, and the bubble finishing run therefore
' makes very few changes to the almost sorted array.

' This means a shell algorithm is very good at pre-sorting
' but falls behind the outright fastest algorithms because
' of its dependance on a slow bubble finish.

' This hybrid shell addresses this issue by replacing the
' bubble with an algorithm that is optimized for pre-sorted
' data - a lightning fast array walker.

Sub strShellHyb(sA() As String, ByVal lbA As Long, ByVal ubA As Long)
   ' Thanks heaps to LukeH for this great algorithm :)
   If Not InitedArray(sA, lbA, ubA) Then Exit Sub
   Dim i As Long, j As Long, k As Long, l As Long
   Dim sItem As String, lpStr As Long, lItem As Long
   Dim walk As Long, find As Long
   Dim eComp As eSortOrder
   With StrPointers_Header
      .pvData = VarPtr(sA(lbA))
      .cElements = ubA - lbA + n1
      .lLbound = lbA
   End With
   eComp = SortOrder                                          ' Initialize compare variable
   lpStr = VarPtr(sItem)                                      ' Cache the pointer to the string variable
   k = ubA - lbA      ' -----===========================----- ' Get the distance from lowerbound to upperbound
   Do: j = j + j + j + n1: Loop Until j > k                   ' Find the initial value for distance
   Do: j = j \ n3                                             ' Reduce distance by two thirds
      For i = lbA + j To ubA                                  ' Loop through each position in our current section
         lItem = StrPointers(i)                               ' Store the string pointer
         CopyMemByR ByVal lpStr, lItem, n4                    ' Put the current value in the buffer sItem (using its pointer)
         l = i - j                                            ' Set the pointer to the value below
         If StrComp(sA(l), sItem, mMethod) = eComp Then       ' Compare the current value with the immediately previous value
            k = i                                             ' If the wrong order then set our temp pointer to the current index
            Do: StrPointers(k) = StrPointers(l)               ' Copy the lower value to the current value
               k = l: l = l - j '-vb2themax-                  ' Adjust the pointers to compare down a level
               If l < lbA Then Exit Do                        ' Make sure we're in-bounds or exit the loop
            Loop While StrComp(sA(l), sItem, mMethod) = eComp ' Keep going as long as current value needs to move down
            StrPointers(k) = lItem                            ' Put the buffered value back in the correct position
      End If: Next                                            ' Increment the inner for loop
   Loop Until j < n12 ' -----===========================----- ' Drop out of the shell algorithm before too small
   walk = lbA                                                 ' Initialize our walker variable
   Do While walk < ubA                                        ' Use optimized insertion sort to finish the job
       walk = walk + n1                                       ' Walk up the array
       lItem = StrPointers(walk)
       CopyMemByR ByVal lpStr, lItem, n4 ' item = sA(walk)
       find = walk
       Do While StrComp(sA(find - n1), sItem, mMethod) = eComp
           StrPointers(find) = StrPointers(find - n1) ' move items up 1
           find = find - n1
           If (find = lbA) Then Exit Do
       Loop '-Repeater v45p ©Rd-
       StrPointers(find) = lItem  ' sA(find) = item
   Loop
   CopyMemByR ByVal lpStr, 0&, n4 ' De-reference our pointer to sItem variable
End Sub

' + ShellHyb Indexed +++++++++++++++++++++++++++++++++++

' This is an indexed implementation of the hybrid shell algorithm.

Sub strShellHybIndexed(sA() As String, idxA() As Long, ByVal lbA As Long, ByVal ubA As Long)
   ' Thanks heaps to LukeH for this great algorithm :)
   If Not InitedArray(sA, lbA, ubA) Then Exit Sub
   Dim i As Long, j As Long, k As Long, l As Long
   Dim s As String, lpStr As Long, lp As Long
   Dim walk As Long, find As Long, idx As Long
   Dim eComp As eSortOrder
   eComp = SortOrder                                            ' Initialize compare variable
   ValidateIndexArray idxA, lbA, ubA                            ' Validate the index array
   lpStr = VarPtr(s)                                            ' Cache the pointer to the string variable
   lp = Sum(VarPtr(sA(lbA)), -(lbA * n4))                       ' Cache the pointer to the array
   k = ubA - lbA      ' -----=============================----- ' Get the distance from lowerbound to upperbound
   Do: j = j + j + j + n1: Loop Until j > k                     ' Find the initial value for distance
   Do: j = j \ n3                                               ' Reduce distance by two thirds
      For i = lbA + j To ubA                                    ' Loop through each position in our current section
         CopyMemByV lpStr, Sum(lp, idxA(i) * n4), n4            ' Put the current value in the string buffer (using its pointer)
         idx = idxA(i)                                          ' Put the current index in the index buffer
         l = i - j                                              ' Set the pointer to the value below
         If StrComp(sA(idxA(l)), s, mMethod) = eComp Then       ' Compare the current value with the immediately previous value
            k = i                                               ' If the wrong order then set our temp pointer to the current index
            Do: idxA(k) = idxA(l)                               ' Copy the lower index to the current index
               k = l: l = l - j '-vb2themax-                    ' Adjust the pointers to compare down a level
               If l < lbA Then Exit Do                          ' Make sure we're in-bounds or exit the loop
            Loop While StrComp(sA(idxA(l)), s, mMethod) = eComp ' Keep going as long as current value needs to move down
            idxA(k) = idx                                       ' Put the buffered index back in the correct position
      End If: Next                                              ' Increment the inner for loop
   Loop Until j < n12 ' -----=============================----- ' Drop out of the shell algorithm before too small
   walk = lbA                                                   ' Initialize our walker variable
   Do While walk < ubA                                          ' Use optimized insertion sort to finish the job
       walk = walk + n1                                         ' Walk up the array
       idx = idxA(walk)                                         ' Put the current index in the index buffer
       CopyMemByV lpStr, Sum(lp, idx * n4), n4                  ' Put the current value in the string buffer (using its pointer)
       find = walk
       Do While StrComp(sA(idxA(find - n1)), s, mMethod) = eComp
           idxA(find) = idxA(find - n1) ' move items up 1
           find = find - n1
           If (find = lbA) Then Exit Do
       Loop '-Repeater v45i ©Rd-
       idxA(find) = idx  ' sA(find) = item
   Loop
   CopyMemByR ByVal lpStr, 0&, n4                               ' De-reference our pointer to variable s
End Sub

' + Inited Array ++++++++++++++++++++++++++++++++++++++++

' This function determines if the passed array is initialized,
' and if so will return -1.

' It will also optionally indicate whether the array can be redimmed;
' in which case it will return -2.

' If the array is uninitialized (never redimmed or has been erased)
' it will return 0 (zero).

Function InitedArray(Arr, lbA As Long, ubA As Long, Optional ByVal bTestRedimable As Boolean) As Long
    ' Thanks to Francesco Balena who solved the Variant headache,
    ' and to Monte Hansen for the ByRef fix
    Dim tSA As SAFEARRAY, lpSA As Long
    Dim iDataType As Integer, lOffset As Long
    On Error GoTo UnInit
    CopyMemByR iDataType, Arr, n2                       ' get the real VarType of the argument, this is similar to VarType(), but returns also the VT_BYREF bit
    If (iDataType And vbArray) = vbArray Then           ' if a valid array was passed
        CopyMemByR lpSA, ByVal Sum(VarPtr(Arr), n8), n4 ' get the address of the SAFEARRAY descriptor stored in the second half of the Variant parameter that has received the array
        If (iDataType And VT_BYREF) Then                ' see whether the function was passed a Variant that contains an array, rather than directly an array in the former case lpSA already points to the SA structure. Thanks to Monte Hansen for this fix
            CopyMemByR lpSA, ByVal lpSA, n4             ' lpSA is a discripter (pointer) to the safearray structure
        End If
        InitedArray = (lpSA <> n0)
        If InitedArray Then
            CopyMemByR tSA.cDims, ByVal lpSA, n4
            If bTestRedimable Then ' Return -2 if redimmable
                InitedArray = InitedArray + ((tSA.fFeatures And FADF_FIXEDSIZE) <> FADF_FIXEDSIZE)
            End If '-©Rd-
            lOffset = n16 + ((tSA.cDims - n1) * n8)
            CopyMemByR tSA.cElements, ByVal Sum(lpSA, lOffset), n8
            tSA.lUbound = tSA.lLbound + tSA.cElements - n1
            If (lbA < tSA.lLbound) Then lbA = tSA.lLbound
            If (ubA > tSA.lUbound) Then ubA = tSA.lUbound
    End If: End If
UnInit:
End Function

' + Validate Index Array +++++++++++++++++++++++++++++++++++++

' This will prepare the passed index array if it is not already.

' This sub-routine determines if the index array passed is either:
' [A] uninitialized or Erased
'     initialized to invalid boundaries
'     initialized to valid boundaries but not prepared
' [B] prepared for the sort process by the For loop
'     has been modified by a previous sort process

' If the condition is determined to be [A] then it is prepared by
' executing the For loop code, otherwise if [B] nothing is done.

' This permits subsequent sorting of the data without interfering
' with the index array if it is already sorted (based on criteria
' that may differ from the current process).

' Otherwise, it ensures that the index array is in the required
' pre-sort state produced by the For loop.

Sub ValidateIndexArray(idxA() As Long, ByVal lbA As Long, ByVal ubA As Long)
    Dim bReDim As Boolean, lb As Long, ub As Long, j As Long
    lb = &H80000000: ub = &H7FFFFFFF
    bReDim = Not InitedArray(idxA, lb, ub)
    If bReDim = False Then
        bReDim = (lbA < lb) Or (ubA > ub)
    End If '-©Rd-
    If bReDim Then ReDim idxA(lbA To ubA) As Long
    If (idxA(lbA) = n0) And (idxA(ubA) = n0) Then
        For j = lbA To ubA
            idxA(j) = j
        Next
    End If
End Sub

' + Sum +++++++++++++++++++++++++++++++++++++++++++++++++

' Enables valid addition and subtraction of unsigned long ints.
' Treats lPtr as an unsigned long and returns an unsigned long.
' Allows safe arithmetic operations on memory address pointers.
' Assumes valid pointer and pointer offset.

Private Function Sum(ByVal lPtr As Long, ByVal lOffset As Long) As Long
    If lOffset > n0 Then
        If lPtr And DW_MSB Then ' if ptr < 0
           Sum = lPtr + lOffset ' ignors > unsigned int max
        ElseIf (lPtr Or DW_MSB) < -lOffset Then
           Sum = lPtr + lOffset ' result is below signed int max
        Else                    ' result wraps to min signed int
           Sum = (lPtr + DW_MSB) + (lOffset + DW_MSB)
        End If
    ElseIf lOffset = n0 Then
        Sum = lPtr
    Else 'If lOffset < 0 Then
        If (lPtr And DW_MSB) = n0 Then ' if ptr > 0
           Sum = lPtr + lOffset ' ignors unsigned int < zero
        ElseIf (lPtr - DW_MSB) >= -lOffset Then
           Sum = lPtr + lOffset ' result is above signed int min
        Else                    ' result wraps to max signed int
           Sum = (lOffset - DW_MSB) + (lPtr - DW_MSB)
        End If
    End If
End Function

' + ArrayPtr ++++++++++++++++++++++++++++++++++++++++++++

' This function returns a pointer to the SAFEARRAY header of
' any Visual Basic array, including a Visual Basic string array.

' Substitutes both ArrPtr and StrArrPtr.

' This function will work with vb5 or vb6 without modification.

Public Function ArrayPtr(Arr) As Long
    Dim iDataType As Integer
    On Error GoTo UnInit
    CopyMemByR iDataType, Arr, n2                           ' get the real VarType of the argument, this is similar to VarType(), but returns also the VT_BYREF bit
    If (iDataType And vbArray) = vbArray Then               ' if a valid array was passed
        CopyMemByR ArrayPtr, ByVal Sum(VarPtr(Arr), n8), n4 ' get the address of the SAFEARRAY descriptor stored in the second half of the Variant parameter that has received the array. Thanks to Francesco Balena.
    End If
UnInit:
End Function

' +++++++++++++++++++++++++++++++++++++++++++++++++++++++

' Rd - crYptic but cRaZy!
