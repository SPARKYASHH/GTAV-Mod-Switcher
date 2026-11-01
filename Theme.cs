using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace Sparkyashh {
    public sealed class Card : Panel {
        public Card() { DoubleBuffered = true; BackColor = Color.White; Padding = new Padding(1); }
        protected override void OnPaint(PaintEventArgs e) {
            base.OnPaint(e);
            using (var pen = new Pen(Color.FromArgb(220,225,218)))
                e.Graphics.DrawRectangle(pen,0,0,Width-1,Height-1);
        }
    }
    public sealed class GroupList : ListView {
        private readonly ImageList rowHeight;
        public GroupList() {
            DoubleBuffered = true;
            View = View.Details; HeaderStyle = ColumnHeaderStyle.None;
            CheckBoxes = true; FullRowSelect = true; MultiSelect = false;
            HideSelection = false; BorderStyle = BorderStyle.None; OwnerDraw = true;
            BackColor = Color.White; ForeColor = Color.FromArgb(32,39,35);
            Columns.Add("Components",380);
            rowHeight = new ImageList(); rowHeight.ImageSize = new Size(1,44);
            rowHeight.Images.Add(new Bitmap(1,44)); SmallImageList = rowHeight;
        }
        protected override void OnSizeChanged(EventArgs e) {
            base.OnSizeChanged(e);
            if (Columns.Count>0) Columns[0].Width = Math.Max(1,ClientSize.Width-4);
        }
        protected override void OnDrawItem(DrawListViewItemEventArgs e) { }
        protected override void OnDrawSubItem(DrawListViewSubItemEventArgs e) {
            var g = e.Graphics;
            var b = e.Bounds;
            var selected = e.Item.Selected;
            using (var brush = new SolidBrush(selected ? Color.FromArgb(234,241,234) : Color.White))
                g.FillRectangle(brush,b);
            using (var pen = new Pen(Color.FromArgb(236,239,234)))
                g.DrawLine(pen,b.Left,b.Bottom-1,b.Right,b.Bottom-1);
            var box = new Rectangle(b.Left+5,b.Top+(b.Height-17)/2,17,17);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using(var fill = new SolidBrush(e.Item.Checked ? Color.FromArgb(37,92,60) : Color.White))
                g.FillRectangle(fill,box);
            using(var pen = new Pen(e.Item.Checked ? Color.FromArgb(37,92,60) : Color.FromArgb(154,164,156)))
                g.DrawRectangle(pen,box);
            if(e.Item.Checked) {
                using(var pen = new Pen(Color.White,2))
                    g.DrawLines(pen,new [] {new Point(box.Left+4,box.Top+8),new Point(box.Left+7,box.Top+11),new Point(box.Left+13,box.Top+5)});
            }
            g.SmoothingMode = SmoothingMode.None;
            TextRenderer.DrawText(g,e.SubItem.Text,Font,new Rectangle(b.Left+34,b.Top,b.Width-40,b.Height),
                Enabled ? ForeColor : SystemColors.GrayText,
                TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix);
            if(Focused && selected) ControlPaint.DrawFocusRectangle(g,new Rectangle(b.Left+29,b.Top+3,b.Width-33,b.Height-6));
        }
        protected override void OnMouseClick(MouseEventArgs e) {
            // Native checkbox handles its own hit area; clicking the text toggles too.
            if(e.Button==MouseButtons.Left) {
                var hit=HitTest(e.Location);
                if(hit.Item!=null && (hit.Location & ListViewHitTestLocations.StateImage)==0)
                    hit.Item.Checked=!hit.Item.Checked;
            }
            base.OnMouseClick(e);
        }
        protected override void Dispose(bool disposing) {
            if(disposing) rowHeight.Dispose();
            base.Dispose(disposing);
        }
    }
}
