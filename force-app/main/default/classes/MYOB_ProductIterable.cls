public class MYOB_ProductIterable implements Iterable<MYOB_ProductResponse.cls_Items> {
    private List<MYOB_ProductResponse.cls_Items> productList;

    // Constructor to accept the list of products
    public MYOB_ProductIterable(List<MYOB_ProductResponse.cls_Items> productList) {
        this.productList = productList;
    }

    // Iterator method to return a custom iterator
    public Iterator<MYOB_ProductResponse.cls_Items> iterator() {
        return new MYOB_ProductIterator(productList);
    }
}