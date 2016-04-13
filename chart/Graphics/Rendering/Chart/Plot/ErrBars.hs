-----------------------------------------------------------------------------
-- |
-- Module      :  Graphics.Rendering.Chart.Plot.ErrBars
-- Copyright   :  (c) Tim Docker 2006, 2014
-- License     :  BSD-style (see chart/COPYRIGHT)
--
-- Plot series of points with associated error bars.
--
{-# LANGUAGE TemplateHaskell #-}

module Graphics.Rendering.Chart.Plot.ErrBars(
    PlotErrBars(..),
    ErrPoint(..),
    ErrValue(..),
    symErrPoint,

    -- * Accessors
    -- | These accessors are generated by template haskell

    plot_errbars_title,
    plot_errbars_line_style,
    plot_errbars_tick_length,
    plot_errbars_overhang,
    plot_errbars_values,
) where

import Control.Lens
import Data.Monoid

import Graphics.Rendering.Chart.Geometry
import Graphics.Rendering.Chart.Drawing
import Graphics.Rendering.Chart.Plot.Types
import Data.Colour (opaque)
import Data.Colour.Names (blue)
import Data.Default.Class

-- | Value for holding a point with associated error bounds for each axis.

data ErrValue x = ErrValue {
      ev_low  :: x,
      ev_best :: x,
      ev_high :: x
} deriving Show

data ErrPoint x y = ErrPoint {
      ep_x :: ErrValue x,
      ep_y :: ErrValue y
} deriving Show

-- | When the error is symmetric, we can simply pass in dx for the error.
symErrPoint :: (Num a, Num b) => a -> b -> a -> b -> ErrPoint a b
symErrPoint x y dx dy = ErrPoint (ErrValue (x-dx) x (x+dx))
                                 (ErrValue (y-dy) y (y+dy))

-- | Value defining a series of error intervals, and a style in
--   which to render them.
data PlotErrBars x y = PlotErrBars {
    _plot_errbars_title       :: String,
    _plot_errbars_line_style  :: LineStyle,
    _plot_errbars_tick_length :: Double,
    _plot_errbars_overhang    :: Double,
    _plot_errbars_values      :: [ErrPoint x y]
}


instance ToPlot PlotErrBars where
    toPlot p = Plot {
        _plot_render     = renderPlotErrBars p,
        _plot_legend     = [(_plot_errbars_title p, renderPlotLegendErrBars p)],
        _plot_all_points = ( concat [ [ev_low x,ev_high x]
                                    | ErrPoint x _ <- pts ]
                           , concat [ [ev_low y,ev_high y]
                                    | ErrPoint _ y <- pts ] )
    }
      where
        pts = _plot_errbars_values p

renderPlotErrBars :: PlotErrBars x y -> PointMapFn x y -> CBProgram ()
renderPlotErrBars p pmap = 
    mapM_ (drawErrBar.epmap) (_plot_errbars_values p)
  where
    epmap (ErrPoint (ErrValue xl x xh) (ErrValue yl y yh)) =
        ErrPoint (ErrValue xl' x' xh') (ErrValue yl' y' yh')
        where (Point x' y')   = pmap' (x,y)
              (Point xl' yl') = pmap' (xl,yl)
              (Point xh' yh') = pmap' (xh,yh)
    drawErrBar = drawErrBar0 p
    pmap'      = mapXY pmap

drawErrBar0 :: PlotErrBars x y -> ErrPoint Double Double -> CBProgram ()
drawErrBar0 ps (ErrPoint (ErrValue xl x xh) (ErrValue yl y yh)) = do
        let tl = _plot_errbars_tick_length ps
        let oh = _plot_errbars_overhang ps
        withLineStyle (_plot_errbars_line_style ps) $ 
          strokePath $ moveTo' (xl-oh) y
                    <> lineTo' (xh+oh) y
                    <> moveTo' x (yl-oh)
                    <> lineTo' x (yh+oh)
                    <> moveTo' xl (y-tl)
                    <> lineTo' xl (y+tl)
                    <> moveTo' (x-tl) yl
                    <> lineTo' (x+tl) yl
                    <> moveTo' xh (y-tl)
                    <> lineTo' xh (y+tl)
                    <> moveTo' (x-tl) yh
                    <> lineTo' (x+tl) yh

renderPlotLegendErrBars :: PlotErrBars x y -> Rect -> CBProgram ()
renderPlotLegendErrBars p (Rect p1 p2) = do
    drawErrBar (symErrPoint (p_x p1)              y dx dx)
    drawErrBar (symErrPoint ((p_x p1 + p_x p2)/2) y dx dx)
    drawErrBar (symErrPoint (p_x p2)              y dx dx)

  where
    drawErrBar = drawErrBar0 p
    dx         = min ((p_x p2 - p_x p1)/6) ((p_y p2 - p_y p1)/2)
    y          = (p_y p1 + p_y p2)/2

instance Default (PlotErrBars x y) where
  def = PlotErrBars 
    { _plot_errbars_title       = ""
    , _plot_errbars_line_style  = solidLine 1 $ opaque blue
    , _plot_errbars_tick_length = 3
    , _plot_errbars_overhang    = 0
    , _plot_errbars_values      = []
    }

$( makeLenses ''PlotErrBars )
