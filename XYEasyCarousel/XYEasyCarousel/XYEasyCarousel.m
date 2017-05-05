//
//  XYEasyCarousel.m
//  XYEasyCarousel
//
//  Created by Yanci on 17/4/26.
//  Copyright © 2017年 Yanci. All rights reserved.
//

#import "XYEasyCarousel.h"
#import <SDWebImage/UIImageView+WebCache.h>

static NSString *const kCellIdentifier = @"cellIdentifier";


@interface XYEasyCarouselCollectionViewCell : UICollectionViewCell
@property (nonatomic,strong)UIImageView *imageView;
@end

@implementation XYEasyCarouselCollectionViewCell

- (void)layoutSubviews {
    _imageView.frame = self.contentView.bounds;
    [super layoutSubviews];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc]init];
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

@end

@interface XYEasyCarousel()<UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) UIPageControl *pageControl;
@property (nonatomic,strong) CADisplayLink *displayLink;
@end

@implementation XYEasyCarousel {
    BOOL _needsReload;  /*! 需要重载 */
    struct {
        unsigned numberOfItems:1;
        unsigned urlForItem:1;
        unsigned imageForItem:1;
    }_datasourceHas;    /*! 数据源存在标识 */
    struct {
        unsigned didClickOnItemAtIndex:1;
    }_delegateHas;      /*! 数据委托存在标识 */
    
    NSUInteger count;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


#pragma mark - life cycle
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        [self setNeedsReload];
    }
    return self;
}

- (void)layoutSubviews {
    self.collectionView.frame = self.bounds;
    [self.pageControl sizeToFit];
    CGRect rectPageControl = self.pageControl.frame;
    rectPageControl.origin.x = (self.bounds.size.width / 2) - (rectPageControl.size.width / 2);
    rectPageControl.origin.y = self.bounds.size.height - rectPageControl.size.height;
    self.pageControl.frame = rectPageControl;
    
    [self _reloadDataIfNeeded];
    [super layoutSubviews];
}

#pragma mark - datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_datasourceHas.numberOfItems) {
        count = [_dataSource numberOfItemsInEasyCarousel:self];
        return UINT16_MAX;
    }
    return 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XYEasyCarouselCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    if (_datasourceHas.imageForItem) {
        cell.imageView.image = [_dataSource imageForItemInEasyCarouselAtIndex:indexPath.row % count];
    }
    else if(_datasourceHas.urlForItem) {
        NSURL *url = [_dataSource urlForItemInEasyCarouselAtIndex:indexPath.row % count];
        [cell.imageView sd_setImageWithURL:url placeholderImage:nil];
    }
    
    return cell;;
}


#pragma mark - delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegateHas.didClickOnItemAtIndex) {
        [_delegate easyCarousel:self didClickOnItemAtIndex:indexPath.row % count];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startDisplayLink) object:nil];
    [self stopDisplayLink];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    double offset_x = scrollView.contentOffset.x;
    double width = scrollView.frame.size.width;
    NSUInteger pageIndex = (uint16_t)(offset_x / width) % count;
    self.pageControl.currentPage = pageIndex;
    [self performSelector:@selector(startDisplayLink) withObject:nil afterDelay:1];
}


#pragma mark - user events
#pragma mark - functions


- (void)commonInit {
    [self addSubview:self.collectionView];
    [self addSubview:self.pageControl];
    
    
}

- (void)setDataSource:(id<XYEasyCarouselDataSource>)dataSource {
    _dataSource = dataSource;
    if ([dataSource respondsToSelector:@selector(numberOfItemsInEasyCarousel:)]) {
        _datasourceHas.numberOfItems = 1;
    }
    if ([dataSource respondsToSelector:@selector(urlForItemInEasyCarouselAtIndex:)]) {
        _datasourceHas.urlForItem = 1;
    
    }
    
    if ([dataSource respondsToSelector:@selector(imageForItemInEasyCarouselAtIndex:)]) {
        _datasourceHas.imageForItem = 1;
    }
}



- (void)setDelegate:(id<XYEasyCarouselDelegate>)delegate {
    _delegate = delegate;
    if ([delegate respondsToSelector:@selector(easyCarousel:didClickOnItemAtIndex:)]) {
        _delegateHas.didClickOnItemAtIndex = 1;
    }
}

- (void)setNeedsReload {
    _needsReload = YES;
    [self setNeedsLayout];
}
- (void)_reloadDataIfNeeded {
    if (_needsReload) {
        [self reloadData];
        _needsReload = NO;
    }
}
- (void)reloadData {
    __weak typeof(self)weakSelf = self;
    [self.collectionView setCollectionViewLayout:  [self flowLayout:0
                                                       paddingRight:0
                                                         paddingTop:0
                                                      paddingBottom:0
                                                         cellHeight:self.bounds.size.height
                                                        cellSpacing:0
                                                          cellCount:1] animated:NO completion:^(BOOL finished) {
        
    }];
    
    [weakSelf.collectionView reloadData];
    
    /** Simply center */
    NSUInteger numberOfItems = [_dataSource numberOfItemsInEasyCarousel:self];
    NSUInteger centerIndexRow = numberOfItems ;
    centerIndexRow =  (UINT16_MAX/2) - ((UINT16_MAX/2) % centerIndexRow);
    
    [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:centerIndexRow inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionNone
                                            animated:NO];
    self.pageControl.numberOfPages = numberOfItems;
    self.pageControl.currentPage = 0;
    
    /** start timer */
    [self stopDisplayLink];
    [self startDisplayLink];
}
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsReload];
}

#pragma mark - functions 


- (void)startDisplayLink
{
    self.displayLink = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(handleDisplayLink:)];
    self.displayLink.frameInterval = 60;

    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSDefaultRunLoopMode];
}

- (void)handleDisplayLink:(CADisplayLink *)displayLink
{
    
    //do something
    NSUInteger currentPage = self.pageControl.currentPage;
    currentPage ++;
    currentPage = currentPage % count;
    
    self.pageControl.currentPage = currentPage;
    
    double offset_x = self.collectionView.contentOffset.x;
    double width = self.collectionView.frame.size.width;
    NSUInteger rowIndex = (uint16_t)(offset_x / width);

    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:rowIndex + 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

- (void)stopDisplayLink
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}
#pragma mark - notification
#pragma mark - getter and setter

- (UICollectionViewFlowLayout *)flowLayout:(CGFloat)left
                              paddingRight:(CGFloat)right
                                paddingTop:(CGFloat)top
                             paddingBottom:(CGFloat)bottom
                                cellHeight:(CGFloat)height
                               cellSpacing:(CGFloat)cellSpacing cellCount:(NSUInteger)cellCount{
    UICollectionViewFlowLayout *_flowLayout = nil;
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc]init];
        CGFloat itemwidth = floor((([UIScreen mainScreen].bounds.size.width - right - left - ((cellSpacing ) * (cellCount - 1) )) / cellCount)) ;
        CGFloat itemheight = height;
        _flowLayout.itemSize = CGSizeMake(itemwidth, itemheight);
        _flowLayout.sectionInset = UIEdgeInsetsMake(top,
                                                    left,
                                                    bottom,
                                                    right);
        _flowLayout.minimumLineSpacing = (cellSpacing);
        _flowLayout.minimumInteritemSpacing = (cellSpacing);
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:
                           [self flowLayout:0
                               paddingRight:0
                                 paddingTop:0
                              paddingBottom:0
                                 cellHeight:0
                                cellSpacing:0
                                  cellCount:0]];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[XYEasyCarouselCollectionViewCell class] forCellWithReuseIdentifier:kCellIdentifier];
    }
    return _collectionView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc]init];
    }
    return _pageControl;
}
@end

