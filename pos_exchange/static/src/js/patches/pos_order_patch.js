import { patch } from "@web/core/utils/patch";
import { PosOrder } from "@point_of_sale/app/models/pos_order";

patch(PosOrder.prototype, {
    /**
     * Overrides the core block that prevents adding positive-quantity products
     * to refund orders. With this patch, cashiers can add the exchange product
     * directly on the same refund receipt. The payment screen then shows the
     * net total: 0 for equal-value exchanges, positive if the new product costs
     * more (customer pays difference), negative if it costs less (partial refund).
     */
    isSaleDisallowed(values, options) {
        return false;
    },
});
