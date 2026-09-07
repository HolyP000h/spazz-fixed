/*
 * canvas2pdf v0.1.7
 * A library to mock HTML5 Canvas calls to generate a PDF document.
 */
(function (global) {
    'use strict';
    
    function Canvas2Pdf(ctx) {
        this.ctx = ctx;
    }
    
    Canvas2Pdf.prototype.stream = function() {
        return this.ctx.stream();
    };
    
    global.Canvas2Pdf = Canvas2Pdf;
}(typeof window !== 'undefined' ? window : this));