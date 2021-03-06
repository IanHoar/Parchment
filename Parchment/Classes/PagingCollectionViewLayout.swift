import UIKit

public class PagingCollectionViewLayout<T: PagingItem where T: Equatable>: UICollectionViewFlowLayout {
  
  var state: PagingState<T>?
  var dataStructure: PagingDataStructure<T>
  
  private let options: PagingOptions
  private let indicatorLayoutAttributes: PagingIndicatorLayoutAttributes
  private let borderLayoutAttributes: PagingBorderLayoutAttributes
  
  private var range: Range<Int> {
    guard let collectionView = collectionView else { return 0...0 }
    return 0..<(collectionView.numberOfItemsInSection(0) - 1)
  }
  
  init(options: PagingOptions, dataStructure: PagingDataStructure<T>) {
    
    self.options = options
    self.dataStructure = dataStructure
    
    indicatorLayoutAttributes = PagingIndicatorLayoutAttributes(
      forDecorationViewOfKind: PagingIndicatorView.reuseIdentifier,
      withIndexPath: NSIndexPath(forItem: 0, inSection: 0))
    
    borderLayoutAttributes = PagingBorderLayoutAttributes(
      forDecorationViewOfKind: PagingBorderView.reuseIdentifier,
      withIndexPath: NSIndexPath(forItem: 1, inSection: 0))
    
    super.init()
    
    configure()
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func configure() {
    sectionInset = options.menuInsets
    minimumLineSpacing = options.menuItemSpacing
    minimumInteritemSpacing = 0
    scrollDirection = .Horizontal
    registerDecorationView(PagingIndicatorView.self)
    registerDecorationView(PagingBorderView.self)
    indicatorLayoutAttributes.configure(options)
    borderLayoutAttributes.configure(options)
  }
  
  public override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
    return true
  }
  
  public override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var layoutAttributes = super.layoutAttributesForElementsInRect(rect)!
    
    let indicatorAttributes = layoutAttributesForDecorationViewOfKind(PagingIndicatorView.reuseIdentifier,
      atIndexPath: NSIndexPath(forItem: 0, inSection: 0))
    
    let borderAttributes = layoutAttributesForDecorationViewOfKind(PagingBorderView.reuseIdentifier,
      atIndexPath: NSIndexPath(forItem: 1, inSection: 0))
    
    if let indicatorAttributes = indicatorAttributes, borderAttributes = borderAttributes {
      layoutAttributes.append(indicatorAttributes)
      layoutAttributes.append(borderAttributes)
    }
    
    return layoutAttributes
  }
  
  public override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    guard
      let state = state,
      let currentIndexPath = dataStructure.indexPathForPagingItem(state.currentPagingItem) else { return nil }
    
    let upcomingIndexPath = upcomingIndexPathForIndexPath(currentIndexPath)
    
    if elementKind == PagingIndicatorView.reuseIdentifier {
      
      let from = PagingIndicatorMetric(
        frame: indicatorFrameForIndex(currentIndexPath.item),
        insets: indicatorInsetsForIndex(currentIndexPath.item))
      
      let to = PagingIndicatorMetric(
        frame: indicatorFrameForIndex(upcomingIndexPath.item),
        insets: indicatorInsetsForIndex(upcomingIndexPath.item))
      
      indicatorLayoutAttributes.update(from: from, to: to, progress: fabs(state.offset))
      return indicatorLayoutAttributes
    }
    
    if elementKind == PagingBorderView.reuseIdentifier {
      borderLayoutAttributes.update(
        contentSize: collectionViewContentSize(),
        bounds: collectionView?.bounds ?? .zero)
      return borderLayoutAttributes
    }
    
    return super.layoutAttributesForDecorationViewOfKind(elementKind, atIndexPath: indexPath)
  }
  
  // MARK: Private
  
  private func upcomingIndexPathForIndexPath(indexPath: NSIndexPath) -> NSIndexPath {
    guard
      let state = state else { return indexPath }
    
    if let upcomingPagingItem = state.upcomingPagingItem, upcomingIndexPath = dataStructure.indexPathForPagingItem(upcomingPagingItem) {
      return upcomingIndexPath
    } else if indexPath.item == range.startIndex {
      return NSIndexPath(forItem: indexPath.item - 1, inSection: 0)
    } else if indexPath.item == range.endIndex {
      return NSIndexPath(forItem: indexPath.item + 1, inSection: 0)
    }
    return indexPath
  }
  
  private func indicatorInsetsForIndex(index: Int) -> PagingIndicatorMetric.Inset {
    if case let .Visible(_, _, insets) = options.indicatorOptions {
      if index == range.startIndex {
        return .Left(insets.left)
      } else if index >= range.endIndex {
        return .Right(insets.right)
      }
    }
    return .None
  }
  
  private func indicatorFrameForIndex(index: Int) -> CGRect {
    guard
      let state = state,
      let currentIndexPath = dataStructure.indexPathForPagingItem(state.currentPagingItem) else { return .zero }
    
    if index < range.startIndex {
      let frame = frameForIndex(currentIndexPath.item)
      return frame.offsetBy(dx: -frame.width, dy: 0)
    } else if index > range.endIndex {
      let frame = frameForIndex(currentIndexPath.item)
      return frame.offsetBy(dx: frame.width, dy: 0)
    } else {
      return frameForIndex(index)
    }
  }
  
  private func frameForIndex(index: Int) -> CGRect {
    let currentIndexPath = NSIndexPath(forItem: index, inSection: 0)
    let layoutAttributes = layoutAttributesForItemAtIndexPath(currentIndexPath)!
    return layoutAttributes.frame
  }
  
}
