public class MYOB_ProductIterator implements Iterator<MYOB_ProductResponse.cls_Items> {
    private List<MYOB_ProductResponse.cls_Items> productList;
    private Integer index = 0;

    // Constructor to accept the list of products
    public MYOB_ProductIterator(List<MYOB_ProductResponse.cls_Items> productList) {
        this.productList = productList;
    }

    // Check if there are more items to iterate
    public Boolean hasNext() {
        return index < productList.size();
    }

    // Return the next item in the list
    public MYOB_ProductResponse.cls_Items next() {
        if (!hasNext()) {
            throw new NoSuchElementException('No more elements to iterate');
        }
        return productList[index++];
    }
}